from jinja2 import Environment, FileSystemLoader
import os
import json

def generate_from_json(json_file_path):
    # Lire le fichier JSON
    with open(json_file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Obtenir le dossier du script actuel
    script_dir = os.path.dirname(os.path.abspath(__file__))
    templates_dir = os.path.join(script_dir, '..', 'Templates', 'Spring')
    
    # Dossier de sortie : directement dans Templates/data (AUCUN sous-dossier)
    output_dir = os.path.join(script_dir, '..', 'Templates', 'data')
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"Templates dir: {templates_dir}")
    print(f"Output dir: {output_dir}")
    
    # Charger les templates
    env = Environment(loader=FileSystemLoader(templates_dir))
    app_template = env.get_template('fichierapp.java.j2')
    controller_template = env.get_template('controller.java.j2')




    
    
    # Parcourir les projets dans le JSON
    for project_name, project_data in data.items():
        print(f"\n Génération du projet: {project_name}")
        
        classes = project_data.get('classes', {})
        package_name = project_name.lower()
        
        # Générer l'Application principale du PROJET (une seule fois)
        app_output = app_template.render(
            project_name=package_name,
            class_name=project_name
        )
        
        # Écrire directement dans data/ (pas de sous-dossier)
        app_file = os.path.join(output_dir, f"{project_name}Application.java")
        with open(app_file, 'w') as f:
            f.write(app_output)
        print(f"  {project_name}Application.java généré dans data/")
        
        # Générer un Controller pour chaque CLASSE
        for class_name, class_info in classes.items():
            controller_output = controller_template.render(
                project_name=package_name,
                class_name=class_name
            )
            
            # Écrire directement dans data/ (pas de sous-dossier)
            controller_file = os.path.join(output_dir, f"{class_name}Controller.java")
            with open(controller_file, 'w') as f:
                f.write(controller_output)
            
            print(f"  {class_name}Controller.java généré dans data/")

# ==================== DÉBUT DU PROGRAMME ====================
if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    json_path = os.path.join(script_dir, '..', '..', 'debug_output.json')
    
    print(f"🔍 Recherche du JSON dans: {os.path.abspath(json_path)}")
    
    if os.path.exists(json_path):
        generate_from_json(json_path)
        print("\nTous les projets ont été générés avec succès!")
    else:
        print(f" Fichier JSON non trouvé: {os.path.abspath(json_path)}")
        print("Vérifiez que debug_output.json est dans /home/charlineb/UML2Code_v2/")