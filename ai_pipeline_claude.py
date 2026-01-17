import argparse
import json
import os
import subprocess
from pathlib import Path
from typing import List, Tuple

import requests


CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
DEFAULT_MODEL_CLAUDE = "claude-3-opus-20240229"
DEFAULT_MODEL_GEMINI = "gemini-2.5-flash"


def _slugify(name: str) -> str:
    return "".join(ch for ch in (name or "") if ch.isalnum()).lower()


def build_user_message(
    stack: str,
    prompt_text: str,
    entities_json: str,
    mapping_entries: List[Tuple[str, str]],
    project_name: str | None = None,
    project_root: Path | None = None,
) -> str:
    existing_tree = _render_existing_tree(project_root)

    mapping_block = "".join(
        [
            f"--- MAPPING {name} BEGIN ---\n{content}\n--- MAPPING {name} END ---\n\n"
            for name, content in mapping_entries
        ]
    )

    return f"""Tu es un générateur de code pour une application {stack}.
Arborescence existante (référence) :
{existing_tree}
Voici exactement trois contenus à utiliser (texte brut envoyés tels quels) :

--- PROMPT BEGIN ---
{prompt_text}
--- PROMPT END ---

{mapping_block}

--- ENTITIES JSON BEGIN ---
{entities_json}
--- ENTITIES JSON END ---

Reste dans ce périmètre : inspire-toi uniquement de ces contenus. Priorise les fichiers indiqués par les mappings, et n'ajoute des fichiers supplémentaires que si c'est nécessaire pour un rendu propre.

À partir de ces informations, produis un JSON unique avec ce format exact :
{{
  "files": [
    {{
      "path": "<chemin/relatif/dans/le/projet>",
      "content": "<contenu du fichier en UTF-8, tel quel>"
    }},
    ...
  ]
}}

Contraintes :
- Utilise l'arborescence existante ci-dessus et évite de créer une structure parallèle.
- Noms de fichiers : ceux indiqués dans le mapping.
- Content : texte du fichier complet, sans encodage base64 ni markdown.
- Pas de TODO/placeholder : fournis des méthodes complètes et compilables (pas de corps vides).
- Utilise les hints 'calls_repository' ou les commentaires de logique : injecte les dépendances (ex: SystemRepository) via constructeur/@RequiredArgsConstructor, crée les interfaces manquantes avec les signatures appelées, et écris des corps de méthodes qui appellent réellement ces dépendances ou lèvent les exceptions prévues (ResourceNotFoundException, ValidationException...).
- Si un fichier non listé dans le mapping est nécessaire, crée-le dans l'emplacement le plus logique de l'arborescence existante.

Réponse attendue : uniquement le JSON ci-dessus, valide, sans markdown, sans commentaires, sans prose, sans triple backticks. Si tu n'as rien à générer, renvoie {{"files":[]}}.

"""


def call_claude(api_key: str, model: str, user_message: str, api_url: str, max_tokens: int, timeout: int) -> str:
    headers = {
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    }
    payload = {
        "model": model,
        "max_tokens": max_tokens,
        "messages": [
            {"role": "user", "content": user_message}
        ],
    }
    resp = requests.post(api_url, headers=headers, data=json.dumps(payload), timeout=timeout)
    resp.raise_for_status()
    data = resp.json()
    # Claude renvoie un tableau content; on concatène les segments textuels
    content = []
    for part in data.get("content", []):
        if part.get("type") == "text":
            content.append(part.get("text", ""))
    return "\n".join(content)


def call_gemini(api_key: str, model: str, user_message: str, api_url: str, max_tokens: int, timeout: int) -> str:
    from google import genai

    client = genai.Client(api_key=api_key)
    try:
        config = {
            "max_output_tokens": max_tokens,
            "response_mime_type": "application/json",
        }
        response = client.models.generate_content(
            model=model,
            contents=user_message,
            config=config,
            request_options={"timeout": timeout},
        )
    except TypeError:
        try:
            response = client.models.generate_content(
                model=model,
                contents=user_message,
                config=config,
            )
        except TypeError:
            response = client.models.generate_content(
                model=model,
                contents=user_message,
            )
    return getattr(response, "text", "") or ""


def _strip_markdown_fences(text: str) -> str:
    """
    Certains modèles renvoient le JSON entouré de ``` ou ```json.
    On retire ces fences pour parser proprement.
    """
    if not isinstance(text, str):
        return text
    stripped = text.strip()
    if not stripped.startswith("```"):
        return stripped
    lines = stripped.splitlines()
    # drop première ligne (``` ou ```json)
    lines = lines[1:]
    # drop dernière ligne si c'est un fence
    if lines and lines[-1].strip().startswith("```"):
        lines = lines[:-1]
    return "\n".join(lines).strip()


def _parse_json_response(text: str) -> dict:
    stripped = text.strip()
    if not stripped:
        raise ValueError("Réponse vide")

    decoder = json.JSONDecoder()
    # Try direct parse first.
    try:
        return json.loads(stripped)
    except json.JSONDecodeError:
        pass

    sanitized = _sanitize_json_text(stripped)
    try:
        return json.loads(sanitized)
    except json.JSONDecodeError:
        pass

    # Scan for the first JSON object/array and parse it with raw_decode.
    for idx, ch in enumerate(stripped):
        if ch not in "{[":
            continue
        try:
            obj, _ = decoder.raw_decode(stripped[idx:])
            return obj
        except json.JSONDecodeError:
            continue

    # Retry scan with sanitized content.
    for idx, ch in enumerate(sanitized):
        if ch not in "{[":
            continue
        try:
            obj, _ = decoder.raw_decode(sanitized[idx:])
            return obj
        except json.JSONDecodeError:
            continue

    raise ValueError("Aucun JSON détecté dans la réponse")


def _render_existing_tree(project_root: Path | None) -> str:
    if project_root is None or not project_root.exists():
        return "- (arborescence indisponible)"

    root = Path(project_root)
    lines: list[str] = []
    max_depth = 3
    max_entries = 120

    def _walk(current: Path, depth: int) -> None:
        if len(lines) >= max_entries:
            return
        if depth > max_depth:
            return
        try:
            entries = sorted(current.iterdir(), key=lambda p: (p.is_file(), p.name.lower()))
        except PermissionError:
            return
        for entry in entries:
            if len(lines) >= max_entries:
                return
            if entry.name.startswith("."):
                continue
            rel = entry.relative_to(root)
            prefix = "  " * depth + "- "
            if entry.is_dir():
                lines.append(f"{prefix}{rel}/")
                _walk(entry, depth + 1)
            else:
                lines.append(f"{prefix}{rel}")

    lines.append(f"- {root.name}/")
    _walk(root, 1)
    if len(lines) >= max_entries:
        lines.append("  - ...")
    return "\n".join(lines)


def _sanitize_json_text(text: str) -> str:
    """Escape invalid backslashes inside JSON string values."""
    out = []
    in_string = False
    escape = False
    i = 0
    valid_escapes = {"\"", "\\", "/", "b", "f", "n", "r", "t", "u"}

    while i < len(text):
        ch = text[i]
        if not in_string:
            out.append(ch)
            if ch == "\"":
                in_string = True
            i += 1
            continue

        if escape:
            # previous char was a backslash
            if ch not in valid_escapes:
                out.append("\\")
            out.append(ch)
            escape = False
            i += 1
            continue

        if ch == "\\":
            escape = True
            out.append(ch)
            i += 1
            continue

        out.append(ch)
        if ch == "\"":
            in_string = False
        i += 1

    if escape:
        out.append("\\")
    return "".join(out)

def main():
    parser = argparse.ArgumentParser(description="Pipeline automatique: envoi à Claude et import dans GeneratedProject.")
    parser.add_argument("--provider", choices=["gemini", "claude"], default="gemini", help="Fournisseur IA (gemini par défaut).")
    parser.add_argument(
        "--stack",
        choices=["spring", "fastapi", "laravel", "nestjs", "dart", "fiber"],
        required=True,
        help="Stack cible.",
    )
    parser.add_argument("--prompt-file", required=True, help="Chemin du prompt agrégé (_prompt.md).")
    parser.add_argument("--mapping-file", help="Chemin d'un mapping JSON (<diagram_id>_<stack>_mapping.json).")
    parser.add_argument("--mapping-dir", help="Dossier contenant les mappings JSON (plusieurs pages).")
    parser.add_argument("--entities-file", required=True, help="Chemin des entités/classes normalisées.")
    parser.add_argument("--output", default="output", help="Répertoire de sortie (contient GeneratedProject et ai_generated/).")
    parser.add_argument("--project-name", help="Nom du projet (sous-dossier de GeneratedProject).")
    parser.add_argument("--project-root", help="Chemin explicite du projet cible (prioritaire sur --project-name).")
    parser.add_argument("--model", help="Modèle à utiliser (par défaut selon provider).")
    parser.add_argument("--api-key", dest="api_key", help="Clé API (sinon GEMINI_API_KEY ou ANTHROPIC_API_KEY selon provider).")
    parser.add_argument("--api-url", help="URL de l'API (override).")
    parser.add_argument("--max-tokens", type=int, default=32768, help="max_tokens à demander au modèle (maxOutputTokens pour Gemini).")
    parser.add_argument("--timeout", type=int, default=300, help="Timeout (s) de l'appel HTTP.")
    args = parser.parse_args()

    provider = args.provider
    if provider == "gemini":
        model = args.model or DEFAULT_MODEL_GEMINI
        api_url = args.api_url or GEMINI_API_URL
        api_key = args.api_key or os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_GENAI_API_KEY")
        if not api_key:
            raise SystemExit("Clé API manquante (paramètre --api-key ou variable GEMINI_API_KEY).")
    else:
        model = args.model or DEFAULT_MODEL_CLAUDE
        api_url = args.api_url or CLAUDE_API_URL
        api_key = args.api_key or os.getenv("ANTHROPIC_API_KEY")
        if not api_key:
            raise SystemExit("Clé API manquante (paramètre --api-key ou variable ANTHROPIC_API_KEY).")

    output_dir = Path(args.output)
    ai_dir = output_dir / "ai_generated" / args.stack
    ai_dir.mkdir(parents=True, exist_ok=True)
    if args.project_root:
        project_root = Path(args.project_root)
    elif args.project_name:
        project_root = output_dir / "GeneratedProject" / args.project_name
    else:
        project_root = output_dir / "GeneratedProject"

    prompt_file = Path(args.prompt_file)
    entities_file = Path(args.entities_file)

    prompt_text = prompt_file.read_text(encoding="utf-8")
    entities_json = entities_file.read_text(encoding="utf-8")

    mapping_entries: List[Tuple[str, str]] = []
    seen_mapping_files: set[str] = set()

    def _append_mapping(path: Path) -> None:
        if not path.is_file():
            return
        name = path.name
        if name in seen_mapping_files:
            return
        mapping_entries.append((name, path.read_text(encoding="utf-8")))
        seen_mapping_files.add(name)

    if args.mapping_file:
        mapping_file = Path(args.mapping_file)
        _append_mapping(mapping_file)
    if args.mapping_dir:
        mapping_dir = Path(args.mapping_dir)
        # Prioritize explicit mapping files but collect everything
        for mf in sorted(mapping_dir.glob("*_mapping*.json")):
            _append_mapping(mf)
        for entry in sorted(mapping_dir.glob("*")):
            _append_mapping(entry)
    if not mapping_entries:
        raise SystemExit("Aucun mapping fourni (utiliser --mapping-file ou --mapping-dir).")

    user_message = build_user_message(
        args.stack,
        prompt_text,
        entities_json,
        mapping_entries,
        project_name=args.project_name,
        project_root=project_root,
    )

    print(f"Appel à {provider} en cours...")
    if provider == "gemini":
        response_text = call_gemini(api_key, model, user_message, api_url, args.max_tokens, args.timeout)
    else:
        response_text = call_claude(api_key, model, user_message, api_url, args.max_tokens, args.timeout)

    # Réponse attendue : un JSON {"files":[{"path": "...", "content": "..."}]}
    json_response_path = ai_dir / "response.json"
    raw_response_path = ai_dir / "response.raw.txt"
    raw_response_path.write_text(response_text, encoding="utf-8")
    response_text = _strip_markdown_fences(response_text)
    try:
        parsed = _parse_json_response(response_text)
        json_response_path.write_text(json.dumps(parsed, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"JSON IA écrit dans {json_response_path}")
    except Exception as exc:
        print(f"Réponse IA non JSON ou invalide. Brute sauvegardée dans {raw_response_path}")
        raise SystemExit(f"Échec parsing JSON IA: {exc}")

    # Import automatique dans GeneratedProject
    subprocess.run(
        [
            "python",
            "ai_import_from_json.py",
            "--json",
            str(json_response_path),
            "--project-root",
            str(project_root),
        ],
        check=True,
    )
    print("Import terminé dans GeneratedProject (collisions sauvegardées en _backup).")


if __name__ == "__main__":
    main()
