# Explication détaillée du système 🚀

Je vais tout vous expliquer étape par étape, comme si vous découvriez le système pour la première fois.

---

## 📋 Table des matières
1. [Vue d'ensemble du problème](#1-vue-densemble-du-problème)
2. [Architecture de la solution](#2-architecture-de-la-solution)
3. [Les structures de données](#3-les-structures-de-données)
4. [Le parsing du diagramme](#4-le-parsing-du-diagramme)
5. [L'analyse et la description](#5-lanalyse-et-la-description)
6. [La génération de code](#6-la-génération-de-code)
7. [Les deux modes : CREATE vs UPDATE](#7-les-deux-modes-create-vs-update)
8. [Comment récupérer et utiliser les fichiers](#8-comment-récupérer-et-utiliser-les-fichiers)
9. [Exemples pratiques complets](#9-exemples-pratiques-complets)

---

## 1. Vue d'ensemble du problème

### Le défi initial
Vous avez :
- 📊 Des diagrammes de séquence (`.drawio`)
- 📄 Des définitions de classes (`.json`)
- 📝 Des descriptions de use cases (texte)

Vous voulez :
- 🎯 Générer automatiquement du code Spring Boot fonctionnel
- 🔄 Pouvoir ajouter de nouvelles fonctionnalités sans écraser l'existant
- 💾 Récupérer les fichiers générés pour les intégrer où vous voulez

### Le problème CLI
Vous travaillez en ligne de commande, donc :
- ❌ Pas d'interface graphique pour récupérer les fichiers
- ❌ Le script ne peut pas "deviner" où mettre les fichiers dans votre projet
- ✅ **Solution** : Le script génère un JSON avec TOUT le contenu, et vous décidez quoi en faire

---

## 2. Architecture de la solution

```
┌─────────────────────────────────────────────────────────┐
│                    VOTRE PROJET                         │
│  ┌───────────────┐         ┌──────────────┐            │
│  │ diagram.drawio│         │ classes.json │            │
│  └───────┬───────┘         └──────┬───────┘            │
│          │                        │                     │
│          └────────┬───────────────┘                     │
│                   ▼                                     │
│         ┌─────────────────────┐                        │
│         │  DiagramToCode      │                        │
│         │  Pipeline           │                        │
│         └─────────┬───────────┘                        │
│                   │                                     │
│                   ▼                                     │
│         ┌─────────────────────┐                        │
│         │ CodeGenerationResult│                        │
│         │  (Objet Python)     │                        │
│         └─────────┬───────────┘                        │
│                   │                                     │
│          ┌────────┴────────┐                           │
│          ▼                 ▼                            │
│    ┌──────────┐      ┌─────────────┐                  │
│    │result.json│      │Objet en     │                  │
│    │(fichier)  │      │mémoire      │                  │
│    └──────────┘      └─────────────┘                  │
│                                                         │
│  Vous choisissez comment utiliser le résultat :        │
│  - Lire le JSON et extraire les fichiers              │
│  - Utiliser l'objet Python directement                │
│  - Intégrer dans votre pipeline de build              │
└─────────────────────────────────────────────────────────┘
```

---

## 3. Les structures de données

### 3.1 `GeneratedFile` - Représente UN fichier généré

```python
@dataclass
class GeneratedFile:
    filename: str           # "UserService.java"
    package: str           # "com.example.app.service"
    content: str           # "package com.example...\n\n@Service\npublic class..."
    full_path: str         # "com/example/app/service/UserService.java"
    file_type: str         # "service", "controller", "entity", etc.
```

**Pourquoi cette structure ?**
- `filename` : Pour savoir comment nommer le fichier
- `package` : Pour connaître le package Java
- `content` : Le code complet du fichier (c'est ça que vous allez écrire sur disque)
- `full_path` : Le chemin relatif depuis `src/main/java/`
- `file_type` : Pour filtrer/organiser (tous les services ensemble, etc.)

**Exemple concret :**
```python
file = GeneratedFile(
    filename="UserService.java",
    package="com.mycompany.user.service",
    content="""package com.mycompany.user.service;

import org.springframework.stereotype.Service;
import java.util.UUID;

@Service
public class UserService {
    
    public void activateUser(UUID userId) {
        // Logique d'activation
    }
}""",
    full_path="com/mycompany/user/service/UserService.java",
    file_type="service"
)

# Comment l'utiliser ?
print(file.filename)  # "UserService.java"
print(file.package)   # "com.mycompany.user.service"
print(file.content)   # Le code complet

# Sauvegarder le fichier
with open(f"src/main/java/{file.full_path}", 'w') as f:
    f.write(file.content)
```

### 3.2 `CodeGenerationResult` - Le résultat complet

```python
@dataclass
class CodeGenerationResult:
    files: List[GeneratedFile]      # Liste de TOUS les fichiers générés
    sequence_description: str        # Description technique du diagramme
    classes_summary: str            # Résumé des classes utilisées
    mode: GenerationMode            # CREATE ou UPDATE
```

**Pourquoi cette structure ?**
- `files` : Contient TOUS les fichiers générés (5, 10, 20 fichiers...)
- `sequence_description` : Pour comprendre ce qui a été analysé
- `classes_summary` : Pour tracer quelles classes ont été utilisées
- `mode` : Pour savoir si c'est une création ou une mise à jour

**Méthodes utiles :**
```python
result = CodeGenerationResult(...)

# 1. Convertir en dictionnaire (pour JSON)
data = result.to_dict()

# 2. Sauvegarder en JSON
result.save_to_json("output.json")

# 3. Récupérer un fichier spécifique
user_service = result.get_file_by_name("UserService.java")

# 4. Récupérer tous les services
services = result.get_files_by_type("service")
```

---

## 4. Le parsing du diagramme

### 4.1 Comment fonctionne `.drawio` ?

Un fichier `.drawio` est en fait du **XML** (parfois compressé en ZIP). Il contient :

```xml
<mxfile>
  <diagram>
    <mxGraphModel>
      <root>
        <!-- Les acteurs -->
        <mxCell id="1" style="umlLifeline" value="User"/>
        <mxCell id="2" style="umlLifeline" value="System"/>
        
        <!-- Les messages -->
        <mxCell id="3" edge="1" source="1" target="2" value="login()"/>
        <mxCell id="4" edge="1" source="2" target="1" value="success" style="dashed"/>
        
        <!-- Les fragments (alt, loop, etc.) -->
        <mxCell style="umlFrame" value="alt [password correct]"/>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

### 4.2 La classe `DrawIOParser`

```python
class DrawIOParser:
    def parse(self):
        """Ouvre le fichier .drawio (ZIP ou XML)"""
        # Essaie d'abord comme ZIP
        try:
            with zipfile.ZipFile(self.filepath, 'r') as z:
                xml_content = z.read(z.namelist()[0])
        except:
            # Sinon, XML plain
            with open(self.filepath, 'r') as f:
                xml_content = f.read()
        
        # Parse le XML
        self.root = ET.fromstring(xml_content)
    
    def extract_actors(self):
        """Trouve tous les acteurs (lifelines)"""
        actors = []
        for cell in self.root.findall(".//mxCell"):
            if 'umlLifeline' in cell.get('style', ''):
                actors.append(cell.get('value'))
        return actors  # ["User", "System", "Database"]
    
    def extract_messages(self):
        """Trouve tous les messages (flèches)"""
        messages = []
        for cell in self.root.findall(".//mxCell"):
            if cell.get('edge') == '1':  # C'est une flèche
                source_id = cell.get('source')
                target_id = cell.get('target')
                label = cell.get('value')
                
                # Type de message
                if 'dashed' in cell.get('style', ''):
                    msg_type = 'return'  # Flèche en pointillés
                else:
                    msg_type = 'call'    # Flèche normale
                
                messages.append(Message(
                    source=self._get_cell_value(source_id),
                    target=self._get_cell_value(target_id),
                    label=label,
                    msg_type=msg_type
                ))
        return messages
```

**Résultat du parsing :**
```python
actors = ["CashRegister", "System", "Account"]
messages = [
    Message(source="CashRegister", target="System", label="NewTransfer()", msg_type="call"),
    Message(source="System", target="CashRegister", label="enterAmount", msg_type="return"),
    Message(source="CashRegister", target="System", label="MakeTransfer(...)", msg_type="call"),
    ...
]
```

---

## 5. L'analyse et la description

### 5.1 La classe `SequenceAnalyzer`

Elle prend le résultat du parsing et génère une **description lisible par un humain** (et par l'IA).

```python
class SequenceAnalyzer:
    def analyze(self):
        # 1. Parse le diagramme
        self.actors = self.parser.extract_actors()
        self.messages = self.parser.extract_messages()
        
        # 2. Génère la description
        return self._generate_description()
    
    def _generate_description(self):
        description = []
        
        # Titre
        description.append("## Fonctionnalité globale")
        description.append("Système de transfert d'argent...")
        
        # Phases
        description.append("### Phase 1 : Initiation")
        description.append("- CashRegister → System : NewTransfer()")
        description.append("- System → CashRegister : enterAmount")
        
        description.append("### Phase 2 : Validation")
        description.append("- CashRegister → System : GetAccount(uuid)")
        # ...
        
        return "\n".join(description)
```

**Exemple de sortie :**
```
## Fonctionnalité globale
Système de transfert d'argent depuis une caisse vers un compte client

## Déroulement du scénario

### Phase 1 : Initiation
- CashRegister → System : NewTransfer()
- System → CashRegister : enterCustomerAccount()

### Phase 2 : Validation du compte
- CashRegister → System : GetAccount(uuid account_id)
- System → Account : CheckIfAccountIsActive(uuid)

### Phase 3 : Vérification des fonds
- CashRegister → System : MakeTransfer(uuid, Account, Float)
- System → CashRegister : CheckIfAmountIsSufficient(uuid, Float)

## Points techniques notables
- Utilisation d'UUID pour l'identification
- Validations et vérifications de sécurité
- Gestion complète des cas d'erreur
```

---

## 6. La génération de code

### 6.1 Construction du prompt pour Claude

Le prompt envoyé à Claude contient :

```python
prompt = f"""
Tu es un expert Spring Boot.

## Description technique du flux
{sequence_description}  # La description générée à l'étape 5

## Use Case métier
{use_case_description}  # Votre description en français

## Classes du domaine
{classes_formatted}     # Les classes du JSON formatées

## Instructions
Génère le code Spring Boot complet avec:
- Controllers (@RestController)
- Services (@Service) avec TOUTE la logique
- Repositories (JpaRepository)
- Entities (@Entity)
- Exceptions (@ControllerAdvice)

**Format de sortie OBLIGATOIRE:**
===FILE_START===
FILENAME: UserService.java
PACKAGE: com.example.app.service
TYPE: service
---
[code complet]
===FILE_END===
"""
```

### 6.2 Appel à Claude

```python
message = self.client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=8000,
    messages=[{"role": "user", "content": prompt}]
)

response_text = message.content[0].text
```

### 6.3 Parsing de la réponse

Claude répond avec plusieurs fichiers dans ce format :

```
===FILE_START===
FILENAME: UserService.java
PACKAGE: com.example.app.service
TYPE: service
---
package com.example.app.service;

import org.springframework.stereotype.Service;
import java.util.UUID;

@Service
public class UserService {
    
    private final UserRepository userRepository;
    
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
    
    public void activateUser(UUID userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new UserNotFoundException(userId));
        user.activate();
        userRepository.save(user);
    }
}
===FILE_END===

===FILE_START===
FILENAME: UserController.java
PACKAGE: com.example.app.controller
TYPE: controller
---
package com.example.app.controller;

import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/users")
public class UserController {
    
    private final UserService userService;
    
    public UserController(UserService userService) {
        this.userService = userService;
    }
    
    @PostMapping("/{id}/activate")
    public ResponseEntity<Void> activateUser(@PathVariable UUID id) {
        userService.activateUser(id);
        return ResponseEntity.ok().build();
    }
}
===FILE_END===
```

Le code parse cette réponse :

```python
def _parse_code_response(self, response: str):
    files = []
    blocks = response.split('===FILE_START===')
    
    for block in blocks[1:]:
        # Extraire métadonnées
        parts = block.split('---')
        metadata = parts[0]
        content = parts[1].split('===FILE_END===')[0]
        
        # Parser les métadonnées
        for line in metadata.split('\n'):
            if line.startswith('FILENAME:'):
                filename = line.replace('FILENAME:', '').strip()
            elif line.startswith('PACKAGE:'):
                package = line.replace('PACKAGE:', '').strip()
            elif line.startswith('TYPE:'):
                file_type = line.replace('TYPE:', '').strip()
        
        # Créer l'objet GeneratedFile
        files.append(GeneratedFile(
            filename=filename,
            package=package,
            content=content.strip(),
            full_path=f"{package.replace('.', '/')}/{filename}",
            file_type=file_type
        ))
    
    return files
```

**Résultat :**
```python
files = [
    GeneratedFile(
        filename="UserService.java",
        package="com.example.app.service",
        content="package com.example.app.service;\n\n@Service\n...",
        full_path="com/example/app/service/UserService.java",
        file_type="service"
    ),
    GeneratedFile(
        filename="UserController.java",
        package="com.example.app.controller",
        content="package com.example.app.controller;\n\n@RestController\n...",
        full_path="com/example/app/controller/UserController.java",
        file_type="controller"
    ),
    # ... autres fichiers
]
```

---

## 7. Les deux modes : CREATE vs UPDATE

### 7.1 Mode CREATE - Créer de nouveaux fichiers

**Quand l'utiliser ?**
- Premier use case d'un module
- Nouvelle fonctionnalité indépendante
- Nouveau microservice

**Ce qu'il fait :**
```python
result = pipeline.process(
    drawio_file="transfer.drawio",
    classes_json_file="classes.json",
    use_case_description="Transfert d'argent",
    mode=GenerationMode.CREATE  # ← MODE CREATE
)
```

Le prompt envoyé à Claude dit :
> "Génère des NOUVEAUX fichiers complets avec toutes les classes nécessaires"

**Résultat :**
```python
result.files = [
    GeneratedFile(filename="TransferService.java", content="...", ...),
    GeneratedFile(filename="TransferController.java", content="...", ...),
    GeneratedFile(filename="CashRegister.java", content="...", ...),
    GeneratedFile(filename="Account.java", content="...", ...),
    # ...
]
```

### 7.2 Mode UPDATE - Ajouter des méthodes à l'existant

**Quand l'utiliser ?**
- Ajouter un nouveau use case à un service existant
- Étendre une fonctionnalité
- Ajouter des endpoints à un controller existant

**Comment ça marche ?**

#### Étape 1 : Préparer les fichiers existants

```python
# Lire les fichiers actuels de votre projet
with open("src/main/java/.../TransferService.java", 'r') as f:
    transfer_service_content = f.read()

with open("src/main/java/.../TransferController.java", 'r') as f:
    transfer_controller_content = f.read()

existing_files = {
    "TransferService.java": transfer_service_content,
    "TransferController.java": transfer_controller_content
}
```

#### Étape 2 : Lancer la génération en mode UPDATE

```python
result = pipeline.process(
    drawio_file="refund.drawio",  # Nouveau diagramme
    classes_json_file="classes.json",
    use_case_description="Remboursement client",  # Nouveau use case
    mode=GenerationMode.UPDATE,  # ← MODE UPDATE
    existing_files=existing_files  # ← Fichiers actuels
)
```

#### Étape 3 : Ce que Claude reçoit comme prompt

```
Tu es un expert Spring Boot. Tu dois METTRE À JOUR des fichiers existants.

## Nouveau Use Case
Remboursement client

## Nouveau flux technique
[Description du diagramme refund.drawio]

## Fichiers existants à modifier

### TransferService.java
```java
package com.example.app.service;

@Service
public class TransferService {
    
    // MÉTHODE EXISTANTE
    public void makeTransfer(UUID from, UUID to, Float amount) {
        // Code existant...
    }
}
```

## Instructions
1. Garde TOUT le code existant
2. Ajoute les NOUVELLES méthodes pour le remboursement
3. Ne supprime RIEN
```

#### Étape 4 : Ce que Claude retourne

```java
package com.example.app.service;

@Service
public class TransferService {
    
    // ============================================
    // MÉTHODE EXISTANTE (intacte)
    // ============================================
    public void makeTransfer(UUID from, UUID to, Float amount) {
        // Code existant inchangé...
    }
    
    // ============================================
    // NOUVELLE MÉTHODE AJOUTÉE
    // ============================================
    public void processRefund(UUID transactionId, String reason) {
        // Nouvelle logique de remboursement
        Transaction transaction = transactionRepository.findById(transactionId)
            .orElseThrow(() -> new TransactionNotFoundException(transactionId));
        
        // Vérifier si le remboursement est possible
        if (!transaction.isRefundable()) {
            throw new RefundNotAllowedException("Transaction not refundable");
        }
        
        // Effectuer le remboursement
        makeTransfer(transaction.getTo(), transaction.getFrom(), transaction.getAmount());
        transaction.setStatus(TransactionStatus.REFUNDED);
        transactionRepository.save(transaction);
    }
}
```

**Le fichier retourné contient :**
- ✅ Toutes les méthodes existantes (inchangées)
- ✅ Les nouvelles méthodes ajoutées
- ✅ Les nouveaux imports si nécessaire

---

## 8. Comment récupérer et utiliser les fichiers

### 8.1 En Python (utilisation programmatique)

```python
from your_script import DiagramToCodePipeline, GenerationMode

# Initialiser le pipeline
pipeline = DiagramToCodePipeline(
    api_key="your-claude-key",
    base_package="com.mycompany.myapp"
)

# Générer le code
result = pipeline.process(
    drawio_file="diagram.drawio",
    classes_json_file="classes.json",
    use_case_description="Mon use case",
    mode=GenerationMode.CREATE
)

# ============================================
# MÉTHODE 1 : Itérer sur les fichiers
# ============================================
for file in result.files:
    print(f"📄 {file.filename}")
    print(f"📦 Package: {file.package}")
    print(f"📍 Path: {file.full_path}")
    print(f"🏷️  Type: {file.file_type}")
    print(f"📝 Content:\n{file.content[:200]}...")  # Premiers 200 caractères
    print("-" * 80)

# ============================================
# MÉTHODE 2 : Récupérer un fichier spécifique
# ============================================
user_service = result.get_file_by_name("UserService.java")
if user_service:
    print(user_service.content)
    
    # Sauvegarder dans votre projet
    project_path = f"my-spring-project/src/main/java/{user_service.full_path}"
    os.makedirs(os.path.dirname(project_path), exist_ok=True)
    with open(project_path, 'w', encoding='utf-8') as f:
        f.write(user_service.content)

# ============================================
# MÉTHODE 3 : Traiter par type de fichier
# ============================================
# Tous les services
services = result.get_files_by_type("service")
for service in services:
    save_to_service_folder(service)

# Tous les controllers
controllers = result.get_files_by_type("controller")
for controller in controllers:
    save_to_controller_folder(controller)

# ============================================
# MÉTHODE 4 : Sauvegarder tout en JSON
# ============================================
result.save_to_json("generation_result.json")

# Plus tard, recharger depuis JSON
with open("generation_result.json", 'r') as f:
    data = json.load(f)
    
for file_data in data['files']:
    filename = file_data['filename']
    content = file_data['content']
    full_path = file_data['full_path']
    # Faire ce que vous voulez avec ces données
```

### 8.2 En CLI (ligne de commande)

```bash
# Exporter les variables d'environnement
export CLAUDE_API_KEY="sk-ant-..."
export BASE_PACKAGE="com.mycompany.transfer"

# Mode CREATE
python script.py create \
    transfer_diagram.drawio \
    classes.json \
    "Système de transfert d'argent" \
    result.json

# Le fichier result.json contient tout
cat result.json
```

**Contenu de `result.json` :**
```json
{
  "files": [
    {
      "filename": "TransferService.java",
      "package": "com.mycompany.transfer.service",
      "content": "package com.mycompany.transfer.service;\n\nimport ...\n\n@Service\npublic class TransferService {\n    ...\n}",
      "full_path": "com/mycompany/transfer/service/TransferService.java",
      "file_type": "service"
    },
    {
      "filename": "TransferController.java",
      "package": "com.mycompany.transfer.controller",
      "content": "package com.mycompany.transfer.controller;\n\n...",
      "full_path": "com/mycompany/transfer/controller/TransferController.java",
      "file_type": "controller"
    }
  ],
  "sequence_description": "## Fonctionnalité globale\nSystème de transfert...",
  "classes_summary": "### User\nType: classe\n...",
  "mode": "create",
  "total_files": 5
}
```

### 8.3 Script pour extraire les fichiers du JSON

```python
# extract_files.py
import json
import os
import sys

def extract_files_from_json(json_path, output_dir):
    """Extrait les fichiers du JSON et les sauvegarde"""
    
    # Charger le JSON
    with open(json_path, 'r', encoding='utf-8') as f:
        result = json.load(f)
    
    print(f"📦 Found {result['total_files']} files in {json_path}")
    
    # Créer le dossier de sortie
    base_dir = os.path.join(output_dir, "src", "main", "java")
    
    # Extraire chaque fichier
    for file_data in result['files']:
        filename = file_data['filename']
        content = file_data['content']
        full_path = file_data['full_path']
        
        # Chemin complet
        file_path = os.path.join(base_dir, full_path)
        
        # Créer les dossiers
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        
        # Écrire le fichier
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✅ Saved: {file_path}")
    
    print(f"\n🎉 All files extracted to {base_dir}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python extract_files.py <result.json> <output_directory>")
        sys.exit(1)
    
    extract_files_from_json(sys.argv[1], sys.argv[2])
```

**Utilisation :**
```bash
# 1. Générer le code
python script.py create diagram.drawio classes.json "Use case" result.json

# 2. Extraire les fichiers dans votre projet
python extract_files.py result.json my-spring-project/

# Structure créée :
# my-spring-project/
# └── src/
#     └── main/
#         └── java/
#             └── com/
#                 └── mycompany/
#                     └── transfer/
#                         ├── controller/
#                         │   └── TransferController.java
#                         ├── service/
#                         │   └── TransferService.java
#                         ├── repository/
#                         │   └── TransferRepository.java
#                         └── entity/
#                             ├── CashRegister.java
#                             └── Account.java
```

---

## 9. Exemples pratiques complets

### 9.1 Scénario 1 : Créer un nouveau module de transfert

```python
# main.py
from your_script import DiagramToCodePipeline, GenerationMode
import os

def setup_project():
    """Configure et génère le code pour le module de transfert"""
    
    # Configuration
    api_key = os.getenv("CLAUDE_API_KEY")
    pipeline = DiagramToCodePipeline(
        api_key=api_key,
        base_package="com.bank.transfer"
    )
    
    # Générer le code
    print("🚀 Génération du module de transfert...")
    result = pipeline.process(
        drawio_file="diagrams/transfer_money.drawio",
        classes_json_file="models/transfer_classes.json",
        use_case_description="""
        Le système permet de transférer de l'argent depuis une caisse
        enregistreuse vers un compte client. Le système vérifie l'existence
        du compte, son statut actif, et la disponibilité des fonds avant
        d'effectuer le transfert.
        """,
        mode=GenerationMode.CREATE,
        output_json="output/transfer_result.json"
    )
    
    # Sauvegarder les fichiers dans le projet
    project_root = "bank-api"
    for file in result.files:
        full_path = os.path.join(
            project_root,
            "src/main/java",
            file.full_path
        )
        
        # Créer les dossiers
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        
        # Écrire le fichier
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(file.content)
        
        print(f"✅ Created: {full_path}")
    
    print(f"\n🎉 Module de transfert créé avec {len(result.files)} fichiers")
    return result

if __name__ == "__main__":
    result = setup_project()
```

### 9.2 Scénario 2 : Ajouter un use case de remboursement

```python
# add_refund_feature.py
from your_script import DiagramToCodePipeline, GenerationMode
import os

def add_refund_to_existing_module():
    """Ajoute la fonctionnalité de remboursement au module existant"""
    
    # 1. Lire les fichiers existants
    print("📖 Lecture des fichiers existants...")
    existing_files = {}

# add_refund_feature.py (suite)
    
    project_root = "bank-api/src/main/java/com/bank/transfer"
    
    # Lire TransferService.java existant
    with open(f"{project_root}/service/TransferService.java", 'r') as f:
        existing_files["TransferService.java"] = f.read()
    
    # Lire TransferController.java existant
    with open(f"{project_root}/controller/TransferController.java", 'r') as f:
        existing_files["TransferController.java"] = f.read()
    
    print(f"   ✅ Chargé {len(existing_files)} fichiers existants")
    
    # 2. Configurer le pipeline
    api_key = os.getenv("CLAUDE_API_KEY")
    pipeline = DiagramToCodePipeline(
        api_key=api_key,
        base_package="com.bank.transfer"
    )
    
    # 3. Générer le code mis à jour
    print("\n🔄 Ajout de la fonctionnalité de remboursement...")
    result = pipeline.process(
        drawio_file="diagrams/refund_money.drawio",  # Nouveau diagramme
        classes_json_file="models/transfer_classes.json",  # Mêmes classes
        use_case_description="""
        Le système permet de rembourser un transfert précédent.
        Il vérifie que la transaction existe, qu'elle est remboursable,
        puis effectue un transfert inverse du montant.
        """,
        mode=GenerationMode.UPDATE,  # ← MODE UPDATE
        existing_files=existing_files,
        output_json="output/refund_result.json"
    )
    
    # 4. Mettre à jour les fichiers dans le projet
    for file in result.files:
        full_path = os.path.join(
            "bank-api/src/main/java",
            file.full_path
        )
        
        # Backup de l'ancien fichier
        if os.path.exists(full_path):
            backup_path = full_path + ".backup"
            os.rename(full_path, backup_path)
            print(f"💾 Backup: {backup_path}")
        
        # Écrire le nouveau fichier
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(file.content)
        
        print(f"✅ Updated: {full_path}")
    
    print(f"\n🎉 Fonctionnalité de remboursement ajoutée!")
    
    # 5. Afficher un résumé des changements
    print("\n📊 Résumé des modifications:")
    for file in result.files:
        print(f"   • {file.filename} ({file.file_type})")
        print(f"     → Nouvelles méthodes ajoutées pour le remboursement")
    
    return result

if __name__ == "__main__":
    result = add_refund_to_existing_module()