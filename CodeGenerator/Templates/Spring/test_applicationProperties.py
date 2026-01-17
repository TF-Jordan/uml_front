import os
from jinja2 import Environment, FileSystemLoader
from pathlib import Path


def generate_application_properties(output_dir, classes, app_name, db="mysql", template_path=None):
    """
    Génère un fichier application.properties depuis un template Jinja2.

    - template_path : chemin complet vers le fichier template Jinja2
    - output_dir : dossier où enregistrer le fichier généré
    - classes : dictionnaire passé au template
    - app_name : nom de l'application (si utilisé dans le template)
    """
    template_path = Path(template_path or Path(__file__).resolve().parent / "application.properties.html")

    # 1. Extraire le dossier + nom de fichier
    template_dir = os.path.dirname(template_path)
    template_filename = os.path.basename(template_path)

    # 2. Retirer extension .html
    filename_no_ext = os.path.splitext(template_filename)[0]

    # 3. Initialiser Jinja2
    env = Environment(loader=FileSystemLoader(template_dir))
    template = env.get_template(template_filename)

    # 4. Rendre le template
    output_content = template.render(classes=classes, app_name=app_name, db=db)

    # 5. S’assurer que le répertoire de sortie existe
    os.makedirs(output_dir, exist_ok=True)

    # 6. Construire le chemin du fichier final
    output_file = os.path.join(output_dir, f"{filename_no_ext}.properties")

    # 7. Écrire le contenu rendu
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(output_content)

    print(f"✔️ Fichier généré : {output_file}")

    return output_file
