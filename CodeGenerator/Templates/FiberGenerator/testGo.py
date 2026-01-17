"""
Test du générateur de code Go/Fiber
"""
import json
import shutil
from pathlib import Path

from CodeGenerator.FiberGenerator.fiber_code_generator import FiberCodeGenerator


def test_generate_ecommerce_project():
    """Test de génération d'un projet e-commerce complet"""

    # Données JSON de test
    project_data = {
        "classes": {
            "user": {
                "type": "classe",
                "attributes": [
                    {"visibility": "+", "attribute_name": "id", "attribute_type": "uuid"},
                    {"visibility": "+", "attribute_name": "email", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "passwordHash", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "createdAt", "attribute_type": "localdatetime"}
                ],
                "methods": [
                    {
                        "name": "activate",
                        "method_type": "void",
                        "visibility": "+",
                        "parameters": []
                    },
                    {
                        "name": "changePassword",
                        "method_type": "void",
                        "visibility": "+",
                        "parameters": [
                            {"param_name": "newPassword", "param_type": "string"}
                        ]
                    }
                ],
                "relationships": [
                    {
                        "user_role_relation": {
                            "type": "association",
                            "source_name": "user",
                            "target_name": "role",
                            "source_cardinality": "1",
                            "target_cardinality": "0..*",
                            "name": "userRoles"
                        }
                    },
                    {
                        "user_address_relation": {
                            "type": "composition",
                            "source_name": "user",
                            "target_name": "address",
                            "source_cardinality": "1",
                            "target_cardinality": "0..*",
                            "name": "userAddresses"
                        }
                    }
                ]
            },
            "admin_user": {
                "type": "classe",
                "attributes": [
                    {"visibility": "+", "attribute_name": "isSuperAdmin", "attribute_type": "boolean"}
                ],
                "methods": [],
                "relationships": [
                    {
                        "admin_user_inheritance": {
                            "type": "inheritance",
                            "source_name": "admin_user",
                            "target_name": "user",
                            "source_cardinality": "1",
                            "target_cardinality": "1",
                            "name": "adminExtendsUser"
                        }
                    }
                ]
            },
            "role": {
                "type": "classe",
                "attributes": [
                    {"visibility": "+", "attribute_name": "code", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "label", "attribute_type": "string"}
                ],
                "methods": [],
                "relationships": [
                    {
                        "role_permission_relation": {
                            "type": "association",
                            "source_name": "role",
                            "target_name": "permission",
                            "source_cardinality": "1",
                            "target_cardinality": "0..*",
                            "name": "rolePermissions"
                        }
                    }
                ]
            },
            "permission": {
                "type": "classe",
                "attributes": [
                    {"visibility": "+", "attribute_name": "name", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "description", "attribute_type": "string"}
                ],
                "methods": [],
                "relationships": []
            },
            "address": {
                "type": "classe",
                "attributes": [
                    {"visibility": "+", "attribute_name": "line1", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "city", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "postalCode", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "country", "attribute_type": "string"}
                ],
                "methods": [],
                "relationships": []
            },
            "product": {
                "type": "classe",
                "attributes": [
                    {"visibility": "+", "attribute_name": "sku", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "label", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "unitPrice", "attribute_type": "bigdecimal"},
                    {"visibility": "+", "attribute_name": "stockQuantity", "attribute_type": "integer"}
                ],
                "methods": [],
                "relationships": [
                    {
                        "product_category_relation": {
                            "type": "aggregation",
                            "source_name": "product",
                            "target_name": "category",
                            "source_cardinality": "0..*",
                            "target_cardinality": "1",
                            "name": "productCategory"
                        }
                    }
                ]
            },
            "category": {
                "type": "classe",
                "attributes": [
                    {"visibility": "+", "attribute_name": "name", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "parentId", "attribute_type": "uuid"}
                ],
                "methods": [],
                "relationships": []
            },
            "order": {
                "type": "classe",
                "attributes": [
                    {"visibility": "+", "attribute_name": "number", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "status", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "totalAmount", "attribute_type": "bigdecimal"},
                    {"visibility": "+", "attribute_name": "placedAt", "attribute_type": "localdatetime"}
                ],
                "methods": [
                    {
                        "name": "cancel",
                        "method_type": "void",
                        "visibility": "+",
                        "parameters": []
                    }
                ],
                "relationships": [
                    {
                        "order_user_relation": {
                            "type": "association",
                            "source_name": "order",
                            "target_name": "user",
                            "source_cardinality": "0..*",
                            "target_cardinality": "1",
                            "name": "orderCustomer"
                        }
                    },
                    {
                        "order_item_composition": {
                            "type": "composition",
                            "source_name": "order",
                            "target_name": "order_item",
                            "source_cardinality": "1",
                            "target_cardinality": "1..*",
                            "name": "orderItems"
                        }
                    }
                ]
            },
            "order_item": {
                "type": "classe",
                "attributes": [
                    {"visibility": "+", "attribute_name": "quantity", "attribute_type": "integer"},
                    {"visibility": "+", "attribute_name": "unitPrice", "attribute_type": "bigdecimal"}
                ],
                "methods": [],
                "relationships": [
                    {
                        "order_item_product_relation": {
                            "type": "association",
                            "source_name": "order_item",
                            "target_name": "product",
                            "source_cardinality": "1..*",
                            "target_cardinality": "1",
                            "name": "orderItemProduct"
                        }
                    }
                ]
            },
            "payment": {
                "type": "classe",
                "attributes": [
                    {"visibility": "+", "attribute_name": "reference", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "method", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "paidAt", "attribute_type": "localdatetime"},
                    {"visibility": "+", "attribute_name": "amount", "attribute_type": "bigdecimal"}
                ],
                "methods": [],
                "relationships": []
            }
        }
    }

    # Nettoyage du dossier de sortie si existant
    output_dir = Path("GeneratedProject/Fiber/ecommerce_api")
    if output_dir.exists():
        shutil.rmtree(output_dir)

    # Génération du projet
    generator = FiberCodeGenerator()
    generator.generate_project("ecommerce_api", project_data)

    # Vérifications
    print("✅ Génération du projet terminée!")
    print(f"📁 Projet généré dans: {output_dir.absolute()}")

    # Vérifier la structure des dossiers
    expected_dirs = [
        "models",
        "handlers",
        "services",
        "repositories",
        "config",
        "routes",
        "utils"
    ]

    for dir_name in expected_dirs:
        dir_path = output_dir / dir_name
        assert dir_path.exists(), f"Le dossier {dir_name} n'existe pas"
        print(f"  ✓ {dir_name}/")

    # Vérifier les fichiers principaux
    expected_files = [
        "main.go",
        "go.mod",
        "README.md",
        ".env.example",
        "config/database.go",
        "routes/routes.go"
    ]

    for file_path in expected_files:
        full_path = output_dir / file_path
        assert full_path.exists(), f"Le fichier {file_path} n'existe pas"
        print(f"  ✓ {file_path}")

    # Vérifier que les modèles ont été générés
    models = ["user", "role", "permission", "address", "product", "category",
              "order", "order_item", "payment", "admin_user"]

    for model in models:
        model_file = output_dir / "models" / f"{model}.go"
        assert model_file.exists(), f"Le modèle {model}.go n'existe pas"
        print(f"  ✓ models/{model}.go")

    # Vérifier que les handlers ont été générés
    for model in models:
        handler_file = output_dir / "handlers" / f"{model}_handler.go"
        assert handler_file.exists(), f"Le handler {model}_handler.go n'existe pas"
        print(f"  ✓ handlers/{model}_handler.go")

    # Vérifier le contenu d'un fichier modèle
    user_model_content = (output_dir / "models" / "user.go").read_text()
    assert "package models" in user_model_content
    assert "type User struct" in user_model_content
    assert "Email" in user_model_content
    assert "PasswordHash" in user_model_content

    print("\n✅ Tous les tests sont passés avec succès!")
    print(f"\n📋 Pour utiliser le projet généré:")
    print(f"   cd {output_dir}")
    print(f"   cp .env .env")
    print(f"   # Configurez votre .env")
    print(f"   go mod download")
    print(f"   go run main.go")


def test_simple_project():
    """Test avec un projet simple"""

    simple_data = {
        "classes": {
            "task": {
                "type": "classe",
                "attributes": [
                    {"visibility": "+", "attribute_name": "title", "attribute_type": "string"},
                    {"visibility": "+", "attribute_name": "description", "attribute_type": "text"},
                    {"visibility": "+", "attribute_name": "completed", "attribute_type": "boolean"}
                ],
                "methods": [
                    {
                        "name": "complete",
                        "method_type": "void",
                        "visibility": "+",
                        "parameters": []
                    }
                ],
                "relationships": []
            }
        }
    }

    output_dir = Path("GeneratedProject/Fiber/simple_todo")
    if output_dir.exists():
        shutil.rmtree(output_dir)

    generator = FiberCodeGenerator()
    generator.generate_project("simple_todo", simple_data)

    print("\n✅ Projet simple généré avec succès!")
    print(f"📁 Emplacement: {output_dir.absolute()}")

    # Vérification basique
    task_model = output_dir / "models" / "task.go"
    assert task_model.exists()

    content = task_model.read_text()
    assert "Title" in content
    assert "Description" in content
    assert "Completed" in content
    assert "func (m *Task) complete()" in content

    print("  ✓ Modèle Task généré correctement")


if __name__ == "__main__":
    print("=" * 60)
    print("Tests du générateur Go/Fiber")
    print("=" * 60)

    try:
        print("\n[TEST 1] Génération d'un projet e-commerce complet")
        print("-" * 60)
        test_generate_ecommerce_project()

        print("\n" + "=" * 60)
        print("[TEST 2] Génération d'un projet simple (TODO)")
        print("-" * 60)
        test_simple_project()

        print("\n" + "=" * 60)
        print("🎉 TOUS LES TESTS SONT PASSÉS!")
        print("=" * 60)

    except AssertionError as e:
        print(f"\n❌ ERREUR: {e}")
    except Exception as e:
        print(f"\n❌ ERREUR INATTENDUE: {e}")
        import traceback

        traceback.print_exc()