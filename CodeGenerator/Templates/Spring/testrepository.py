import json
import os
from jinja2 import Environment, FileSystemLoader
from pathlib import Path
# Chem
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
JSON_FILE = os.path.join(SCRIPT_DIR, "debug_output.json")
TEMPLATE_FILE = os.path.join(SCRIPT_DIR, "repository.html")
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "repositories")  

def load_json(file_path):
    """Charge le fichier JSON"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            print(f"✅ Fichier JSON chargé avec succès")
            print(f"📋 Clés disponibles dans le JSON: {list(data.keys())}")
            return data
    except FileNotFoundError:
        print(f"❌ Fichier non trouvé: {file_path}")
        return None
    except json.JSONDecodeError as e:
        print(f"❌ Erreur de parsing JSON: {e}")
        return None

def get_java_type(uml_type):
    """Convertit un type UML en type Java"""
    type_mapping = {
        'String': 'String',
        'Integer': 'Integer',
        'int': 'int',
        'Long': 'Long',
        'long': 'long',
        'Double': 'Double',
        'double': 'double',
        'Boolean': 'Boolean',
        'boolean': 'boolean',
        'Date': 'java.util.Date',
        'LocalDate': 'LocalDate',
        'LocalDateTime': 'LocalDateTime',
        'BigDecimal': 'BigDecimal',
        'Uuid': 'UUID',
        'UUID': 'UUID',
        'List': 'List',
        'Set': 'Set',
        'Map': 'Map'
    }
    return type_mapping.get(uml_type, uml_type)

def parse_class_attributes(class_data):
    """Parse les attributs d'une classe et détermine leurs propriétés"""
    attributes = []
    compositions = []
    aggregations = []
    has_date_attributes = False
    
    for attr in class_data.get('attributes', []):
        attr_name = attr.get('attribute_name', '')
        attr_type = attr.get('attribute_type', 'String')
        visibility = attr.get('visibility', 'private')
        
        # Vérifier si c'est un attribut de date
        if attr_type in ['LocalDateTime', 'LocalDate', 'Date']:
            has_date_attributes = True
        
        # Déterminer si c'est une composition (#) ou agrégation ($)
        if attr_name.endswith('#'):
            compositions.append({
                'name': attr_name.rstrip('#'),
                'type': attr_type
            })
        elif attr_name.endswith('$'):
            aggregations.append({
                'name': attr_name.rstrip('$'),
                'type': attr_type
            })
        elif visibility == 'public':
            # C'est un attribut normal public
            attributes.append({
                'name': attr_name,
                'type': get_java_type(attr_type),
                'searchable': attr_type == 'String' or attr_name in ['email', 'sku', 'number', 'reference', 'trackingNumber', 'invoiceNumber', 'code', 'name'],
                'unique': attr_name in ['email', 'sku', 'number', 'reference', 'trackingNumber', 'invoiceNumber', 'code'],
                'deletable': attr_name in ['email', 'sku', 'code']
            })
    
    return {
        'attributes': attributes,
        'compositions': compositions,
        'aggregations': aggregations,
        'hasDateAttributes': has_date_attributes
    }

def prepare_repository_data(class_name, class_data):
    """Prépare les données pour le template repository"""
    parsed = parse_class_attributes(class_data)
    
    return {
        'name': class_name.lower(),
        'attributes': parsed['attributes'],
        'compositions': parsed['compositions'],
        'aggregations': parsed['aggregations'],
        'hasDateAttributes': parsed['hasDateAttributes']
    }

def generate_repositories(json_file, template_file, output_dir):
    """Génère les repositories à partir du JSON et du template Jinja2"""
    
    print(f"📖 Lecture du fichier {json_file}...")
    data = load_json(json_file)
    
    if data is None:
        return
    
    # Vérifier la structure du JSON
    classes_data = None
    project_name = None
    
    if 'classes' in data:
        classes_data = data['classes']
    else:
        # Chercher dans les projets
        for key, value in data.items():
            if isinstance(value, dict) and 'classes' in value:
                print(f"💡 Projet trouvé: '{key}'")
                project_name = key
                classes_data = value['classes']
                break
        
        if classes_data is None:
            print(f"❌ La clé 'classes' n'existe pas dans le JSON")
            return
    
    # Créer le répertoire de sortie
    os.makedirs(output_dir, exist_ok=True)
    print(f"📁 Répertoire de sortie: {output_dir}")
    
    # Configurer Jinja2
    template_dir = os.path.dirname(os.path.abspath(template_file))
    template_name = os.path.basename(template_file)
    
    env = Environment(loader=FileSystemLoader(template_dir))
    
    # Ajouter des filtres personnalisés
    def capitalize_filter(value):
        if not value:
            return value
        return value[0].upper() + value[1:]
    
    env.filters['capitalize'] = capitalize_filter
    env.filters['java_type'] = get_java_type
    
    try:
        template = env.get_template(template_name)
        print(f"✅ Template chargé: {template_name}")
    except Exception as e:
        print(f"❌ Erreur lors du chargement du template: {e}")
        return
    
    # Générer un Repository pour chaque classe
    generated_count = 0
    skipped_count = 0
    
    for class_id, class_data in classes_data.items():
        class_type = class_data.get('type', '')
        
        # Ignorer les interfaces et implémentations
        if 'implementation' in class_type or 'interface' in class_type.lower():
            print(f"⏭️  Ignoré (interface): {class_id}")
            skipped_count += 1
            continue
        
        # Nettoyer le nom de la classe (enlever extends, implements, etc.)
        class_name = class_id
        if ',' in class_type:
            # Extraire le vrai nom si extends ou implements
            parts = class_type.split(',')
            for part in parts:
                if 'extends' in part:
                    class_name = class_id  # Utiliser l'ID original
                    break
        
        print(f"\n🔄 Génération du repository pour: {class_name}")
        
        # Préparer les données
        repo_data = prepare_repository_data(class_name, class_data)
        
        context = {
            'route': 'com.example',
            'data': repo_data,
            'UUID': 'UUID'
        }
        
        # Afficher les données préparées
        print(f"   📊 Attributs: {len(repo_data['attributes'])}")
        print(f"   🔗 Compositions: {len(repo_data['compositions'])}")
        print(f"   🔗 Agrégations: {len(repo_data['aggregations'])}")
        print(f"   📅 Date attributes: {repo_data['hasDateAttributes']}")
        
        # Générer le code
        try:
            rendered_code = template.render(context)
            
            # Écrire le fichier
            output_file = os.path.join(output_dir, f"{class_name}Repository.java")
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(rendered_code)
            
            print(f"   ✅ Généré: {class_name}Repository.java")
            generated_count += 1
            
            # Afficher un aperçu du code généré (premières lignes)
            lines = rendered_code.split('\n')[:15]
            print(f"   📝 Aperçu:")
            for line in lines:
                print(f"      {line}")
            print(f"      ...")
            
        except Exception as e:
            print(f"   ❌ Erreur lors de la génération de {class_name}Repository: {e}")
            import traceback
            traceback.print_exc()
    
    print(f"\n" + "="*60)
    print(f"🎉 Génération terminée!")
    print(f"   ✅ Repositories créés: {generated_count}")
    print(f"   ⏭️  Classes ignorées: {skipped_count}")
    print(f"   📁 Dossier de sortie: {output_dir}")
    print("="*60)

def test_single_class():
    """Test avec une seule classe pour debug"""
    print("\n" + "="*60)
    print("🧪 TEST AVEC UNE SEULE CLASSE (User)")
    print("="*60 + "\n")
    
    # Données de test pour User
    test_data = {
        'name': 'user',
        'attributes': [
            {
                'name': 'id',
                'type': 'UUID',
                'searchable': False,
                'unique': False,
                'deletable': False
            },
            {
                'name': 'email',
                'type': 'String',
                'searchable': True,
                'unique': True,
                'deletable': True
            },
            {
                'name': 'passwordHash',
                'type': 'String',
                'searchable': False,
                'unique': False,
                'deletable': False
            },
            {
                'name': 'createdAt',
                'type': 'LocalDateTime',
                'searchable': False,
                'unique': False,
                'deletable': False
            }
        ],
        'compositions': [],
        'aggregations': [],
        'hasDateAttributes': True
    }
    
    context = {
        'route': 'com.example',
        'data': test_data,
        'UUID': 'UUID'
    }
    
    template_dir = os.path.dirname(os.path.abspath(TEMPLATE_FILE))
    template_name = os.path.basename(TEMPLATE_FILE)
    
    env = Environment(loader=FileSystemLoader(template_dir))
    
    def capitalize_filter(value):
        if not value:
            return value
        return value[0].upper() + value[1:]
    
    env.filters['capitalize'] = capitalize_filter
    
    try:
        template = env.get_template(template_name)
        rendered = template.render(context)
        
        print("📝 Code généré pour UserRepository:")
        print("-" * 60)
        print(rendered)
        print("-" * 60)
        
    except Exception as e:
        print(f"❌ Erreur: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    import sys
    
    # Si argument --test, faire un test simple
    if len(sys.argv) > 1 and sys.argv[1] == '--test':
        test_single_class()
    else:
        # Génération complète
        try:
            generate_repositories(JSON_FILE, TEMPLATE_FILE, OUTPUT_DIR)
        except Exception as e:
            print(f"❌ Erreur lors de la génération: {str(e)}")
            import traceback
            traceback.print_exc()
            exit(1)

