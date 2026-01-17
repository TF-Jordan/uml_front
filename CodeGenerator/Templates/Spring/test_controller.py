import os
from pathlib import Path

from jinja2 import Environment, FileSystemLoader


def generate_java_from_template(output_dir, classes, template_path=None):
    """
    Génère un fichier .java depuis un template Jinja2.

    Arguments :
        - template_path : chemin complet vers le fichier template .html Jinja2
        - output_dir : répertoire où générer le fichier .java
        - classes : dictionnaire fourni au moteur Jinja2
    """

    template_path = Path(template_path or Path(__file__).resolve().parent / "controller.java.j2")

    # 1. Séparer dossier et nom du fichier template
    template_dir = os.path.dirname(template_path)
    template_filename = os.path.basename(template_path)

    # 2. Changer l'extension : .j2/.html → .java
    filename_no_ext = os.path.splitext(template_filename)[0]
    output_filename = filename_no_ext if filename_no_ext.endswith(".java") else f"{filename_no_ext}.java"

    # 3. Charger l’environnement Jinja2
    env = Environment(loader=FileSystemLoader(template_dir))
    template = env.get_template(template_filename)

    # 4. Rendre le template
    output_content = template.render(classes=classes)

    # 5. Créer le répertoire de sortie si nécessaire
    os.makedirs(output_dir, exist_ok=True)

    # 6. Construire chemin du fichier généré
    output_file_path = os.path.join(output_dir, output_filename)

    # 7. Écrire le fichier Java
    with open(output_file_path, "w", encoding="utf-8") as f:
        f.write(output_content)

    print(f"✔️ Fichier Java généré : {output_file_path}")
    return output_file_path
