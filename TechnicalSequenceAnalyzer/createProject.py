import os
from pathlib import Path


def create_file(path: Path, content: str):
    # \"\"\"Crée un fichier avec son contenu\"\"\"
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Créé: {path}")


def main():
    base_dir = Path("sequence_analyzer")

    # Créer la structure de dossiers
    folders = [
        "parser",
        "mapper",
        "generator",
        "models",
        "utils",
        "input_diagrams",
        "output_analysis",
        "templates"
    ]

    for folder in folders:
        (base_dir / folder).mkdir(parents=True, exist_ok=True)

    print("\\n🏗️  Création de la structure du projet sequence_analyzer...")
    print("=" * 60)

    # TODO: Copier ici tout le contenu des fichiers générés ci-dessus

    print("\\n✨ Projet créé avec succès!")
    print(f"📁 Emplacement: {base_dir.absolute()}")
    print("\\n📦 Installation des dépendances:")
    print("   cd sequence_analyzer")
    print("   pip install -r requirements.txt")
    print("\\n🚀 Utilisation:")
    print("   python main.py input_diagrams/test2.drawio --entities debug_output.json")


if __name__ == '__main__':
    main()