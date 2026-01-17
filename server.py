"""
Serveur FastAPI minimal pour l'orchestration du pipeline de génération de code.
Tout-en-un : upload, génération avec SSE, téléchargement, nettoyage automatique.
"""

from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from fastapi.responses import StreamingResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, AsyncGenerator
from pathlib import Path
import shutil
import zipfile
import asyncio
import json
import sys
import subprocess
import uuid

# Imports du pipeline existant (SANS MODIFICATION)
from Lexer.lexer import Lexer
from Parser.parser import Parser
from Semantic_Analyzer.pipeline import run_pipeline
from CodeGenerator.SpringGenerator.spring_code_generator import SpringCodeGenerator
from CodeGenerator.FastApiGenerator.fastapi_code_generator import FastApiCodeGenerator
from CodeGenerator.LaravelGenerator.laravel_code_generator import LaravelCodeGenerator
from CodeGenerator.NestJSGenerator.nestjs_code_generator import NestJSCodeGenerator
from CodeGenerator.DartGenerator import DartCodeGenerator
from CodeGenerator.FiberGenerator.fiber_code_generator import FiberCodeGenerator

# Configuration du sequence_analyzer
SEQ_ROOT = Path(__file__).resolve().parent / "TechnicalSequenceAnalyzer" / "sequence_analyzer"
if str(SEQ_ROOT) not in sys.path:
    sys.path.insert(0, str(SEQ_ROOT))


# ============================================================================
# MODÈLES DE DONNÉES
# ============================================================================

class GenerationRequest(BaseModel):
    """Requête de génération."""
    project_name: str
    stack: str  # spring, fastapi, laravel, nestjs, dart, fiber
    class_diagram_filename: str
    has_sequence_diagram: bool = False
    sequence_diagram_filename: Optional[str] = None
    description: Optional[str] = None


# ============================================================================
# APPLICATION FASTAPI
# ============================================================================

app = FastAPI(title="Code Generation Pipeline API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Répertoires
UPLOAD_DIR = Path("uploads")
CLASS_DIR = UPLOAD_DIR / "class_diagrams"
SEQ_DIR = UPLOAD_DIR / "sequence_diagrams"
OUTPUT_DIR = Path("output")

# Création des répertoires
CLASS_DIR.mkdir(parents=True, exist_ok=True)
SEQ_DIR.mkdir(parents=True, exist_ok=True)
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

async def save_upload(file: UploadFile, directory: Path) -> str:
    """Sauvegarde un fichier uploadé."""
    filename = f"{Path(file.filename).stem}_{uuid.uuid4().hex[:8]}{Path(file.filename).suffix}"
    filepath = directory / filename
    content = await file.read()
    filepath.write_bytes(content)
    return filename


def create_zip(source_dir: Path, zip_path: Path):
    """Crée un ZIP d'un répertoire."""
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for file in source_dir.rglob('*'):
            if file.is_file():
                zipf.write(file, file.relative_to(source_dir))


async def cleanup_project(project_name: str, zip_path: Path):
    """Nettoie tous les fichiers d'un projet."""
    await asyncio.sleep(2)  # Attendre que le téléchargement soit terminé
    
    try:
        # Suppression du ZIP
        if zip_path.exists():
            zip_path.unlink()
        
        # Suppression du projet
        project_dir = OUTPUT_DIR / project_name
        if project_dir.exists():
            shutil.rmtree(project_dir)
        
        # Suppression des diagrammes
        for diagram in CLASS_DIR.glob(f"*{project_name}*"):
            diagram.unlink()
        for diagram in SEQ_DIR.glob(f"*{project_name}*"):
            diagram.unlink()
        
        print(f"✅ Nettoyage terminé: {project_name}")
    except Exception as e:
        print(f"⚠️ Erreur nettoyage {project_name}: {e}")


# ============================================================================
# ENDPOINTS
# ============================================================================

@app.get("/")
async def root():
    """Page d'accueil."""
    return {"message": "Code Generation Pipeline API", "docs": "/docs"}


@app.get("/api/health")
async def health():
    """Vérification de santé."""
    return {"status": "healthy", "version": "1.0.0"}


@app.post("/api/upload/class-diagram")
async def upload_class_diagram(file: UploadFile = File(...)):
    """Téléverse le diagramme de classes."""
    if not file.filename.endswith(('.drawio', '.xml')):
        raise HTTPException(400, "Extension invalide (.drawio ou .xml requis)")
    
    filename = await save_upload(file, CLASS_DIR)
    return {
        "success": True,
        "message": "Diagramme de classes téléversé",
        "file_path": filename,
        "file_type": "class_diagram"
    }


@app.post("/api/upload/sequence-diagram")
async def upload_sequence_diagram(file: UploadFile = File(...)):
    """Téléverse le diagramme de séquences."""
    if not file.filename.endswith(('.drawio', '.xml')):
        raise HTTPException(400, "Extension invalide (.drawio ou .xml requis)")
    
    filename = await save_upload(file, SEQ_DIR)
    return {
        "success": True,
        "message": "Diagramme de séquences téléversé",
        "file_path": filename,
        "file_type": "sequence_diagram"
    }


@app.post("/api/generate/stream")
async def generate_stream(request: GenerationRequest):
    """Génère le projet avec suivi en temps réel (SSE)."""
    
    async def event_stream() -> AsyncGenerator[str, None]:
        try:
            # Validation des fichiers
            class_diagram = CLASS_DIR / request.class_diagram_filename
            if not class_diagram.exists():
                yield f"data: {json.dumps({'error': 'Diagramme de classes introuvable'})}\n\n"
                return
            
            sequence_diagram = None
            if request.has_sequence_diagram and request.sequence_diagram_filename:
                sequence_diagram = SEQ_DIR / request.sequence_diagram_filename
                if not sequence_diagram.exists():
                    yield f"data: {json.dumps({'error': 'Diagramme de séquences introuvable'})}\n\n"
                    return
            
            output_dir = OUTPUT_DIR / request.project_name
            if output_dir.exists():
                shutil.rmtree(output_dir)
            output_dir.mkdir(parents=True)
            
            # ÉTAPE 1: Lecture
            yield f"data: {json.dumps({'step': 'read', 'status': 'started', 'message': 'Lecture du diagramme...', 'progress': 10})}\n\n"
            await asyncio.sleep(1)
            xml_content = class_diagram.read_text(encoding="utf-8")
            yield f"data: {json.dumps({'step': 'read', 'status': 'completed', 'message': 'Diagramme lu', 'progress': 15})}\n\n"
            
            # ÉTAPE 2: Lexer
            yield f"data: {json.dumps({'step': 'lexer', 'status': 'started', 'message': 'Analyse lexicale...', 'progress': 20})}\n\n"
            await asyncio.sleep(1.5)
            lexed = await asyncio.to_thread(Lexer(xml_content).execute)
            yield f"data: {json.dumps({'step': 'lexer', 'status': 'completed', 'message': 'Analyse lexicale terminée', 'progress': 30})}\n\n"
            
            # ÉTAPE 3: Parser
            yield f"data: {json.dumps({'step': 'parser', 'status': 'started', 'message': 'Analyse syntaxique...', 'progress': 35})}\n\n"
            await asyncio.sleep(1)
            parsed = await asyncio.to_thread(Parser(lexed).execute)
            raw_path = output_dir / "structure_Parser.json"
            raw_path.write_text(json.dumps(parsed, indent=2, ensure_ascii=False), encoding="utf-8")
            yield f"data: {json.dumps({'step': 'parser', 'status': 'completed', 'message': 'Analyse syntaxique terminée', 'progress': 45})}\n\n"
            
            # ÉTAPE 4: Sémantique
            yield f"data: {json.dumps({'step': 'semantic', 'status': 'started', 'message': 'Analyse sémantique...', 'progress': 50})}\n\n"
            await asyncio.sleep(2)
            normalized = await asyncio.to_thread(run_pipeline, raw_path, language="java", project_type=request.stack)
            norm_path = output_dir / f"{class_diagram.stem}_normalized.json"
            norm_path.write_text(json.dumps(normalized, indent=2, ensure_ascii=False), encoding="utf-8")
            yield f"data: {json.dumps({'step': 'semantic', 'status': 'completed', 'message': 'Analyse sémantique terminée', 'progress': 60})}\n\n"
            
            # ÉTAPE 5: Génération de code
            yield f"data: {json.dumps({'step': 'codegen', 'status': 'started', 'message': f'Génération {request.stack.upper()}...', 'progress': 65})}\n\n"
            await asyncio.sleep(2.5)
            
            output_root = output_dir / "GeneratedProject"
            if request.stack == "nestjs":
                await asyncio.to_thread(NestJSCodeGenerator(output_root=output_root).generate_project, request.project_name, normalized)
            elif request.stack == "laravel":
                await asyncio.to_thread(LaravelCodeGenerator(output_root=output_root).generate_project, request.project_name, normalized)
            elif request.stack == "spring":
                await asyncio.to_thread(SpringCodeGenerator(output_root=output_root).generate_project, request.project_name, normalized)
            elif request.stack == "fastapi":
                await asyncio.to_thread(FastApiCodeGenerator(output_root=output_root).generate_project, request.project_name, normalized)
            elif request.stack == "dart":
                await asyncio.to_thread(DartCodeGenerator(output_root=output_root).generate_project, request.project_name, normalized)
            elif request.stack == "fiber":
                await asyncio.to_thread(FiberCodeGenerator(output_root=output_root).generate_project, request.project_name, normalized)
            
            yield f"data: {json.dumps({'step': 'codegen', 'status': 'completed', 'message': 'Code généré', 'progress': 80})}\n\n"
            
            # ÉTAPE 6: Diagramme de séquences (optionnel)
            if sequence_diagram:
                yield f"data: {json.dumps({'step': 'sequence', 'status': 'started', 'message': 'Traitement séquences...', 'progress': 85})}\n\n"
                await asyncio.sleep(2)
                
                seq_output = output_dir / "sequence_output"
                seq_args = [
                    sys.executable, str(SEQ_ROOT / "main.py"),
                    str(sequence_diagram), "--entities", str(norm_path),
                    "--output", str(seq_output), "--stack", request.stack
                ]
                if request.description:
                    seq_args.extend(["--use-case", request.description])
                
                process = await asyncio.create_subprocess_exec(*seq_args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                await process.communicate()
                
                yield f"data: {json.dumps({'step': 'sequence', 'status': 'completed', 'message': 'Logique métier complétée', 'progress': 95})}\n\n"
            
            # ÉTAPE FINALE
            yield f"data: {json.dumps({'step': 'done', 'status': 'completed', 'message': 'Génération terminée!', 'progress': 100})}\n\n"
        
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)})}\n\n"
    
    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "Connection": "keep-alive"}
    )


@app.get("/api/download/{project_name}")
async def download(project_name: str, background_tasks: BackgroundTasks):
    """Télécharge le projet et planifie le nettoyage."""
    project_dir = OUTPUT_DIR / project_name / "GeneratedProject"
    if not project_dir.exists():
        raise HTTPException(404, "Projet introuvable")
    
    zip_path = OUTPUT_DIR / f"{project_name}.zip"
    await asyncio.to_thread(create_zip, project_dir, zip_path)
    
    # Nettoyage en arrière-plan
    background_tasks.add_task(cleanup_project, project_name, zip_path)
    
    return FileResponse(
        str(zip_path),
        media_type="application/zip",
        filename=f"{project_name}.zip"
    )


@app.delete("/api/cleanup/{project_name}")
async def manual_cleanup(project_name: str):
    """Nettoyage manuel."""
    zip_path = OUTPUT_DIR / f"{project_name}.zip"
    await cleanup_project(project_name, zip_path)
    return {"success": True, "message": f"Projet {project_name} nettoyé"}


# ============================================================================
# LANCEMENT
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.127.0.1", port=8000, log_level="info")
