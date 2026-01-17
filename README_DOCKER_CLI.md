# UML2Code - Docker CLI

This project can run as a CLI inside Docker (no API, no frontend). Flutter can call the CLI by running `docker run`.

## Build

```bash
docker build -t uml2code-cli .
```

## Pull (distribution)

If you use the prebuilt image from Docker Hub, pull it instead of building locally:

```bash
docker pull blhack/uml2code-cli:latest
```

You can override the image name with `UML2CODE_IMAGE`.

### Faster rebuilds (cache pip downloads)

This image uses a BuildKit cache for pip. When `requirements.docker.txt` does not change,
Docker will reuse the cached wheels and avoid re-downloading dependencies.

```bash
DOCKER_BUILDKIT=1 docker build -t uml2code-cli .
```

Tip: avoid `--pull` if you want to keep the base image cached.

## Run

```bash
docker run --rm \
  -v "$PWD:/workspace" -w /workspace \
  uml2code-cli /workspace/config.json
```

## Run on Linux / macOS / Windows

Linux (bash):

```bash
docker run --rm \
  -v "$PWD:/workspace" -w /workspace \
  uml2code-cli /workspace/config.json
```

macOS (zsh):

```bash
docker run --rm \
  -v "$PWD:/workspace" -w /workspace \
  uml2code-cli /workspace/config.json
```

Windows (PowerShell):

```powershell
docker run --rm `
  -v "$PWD:/workspace" -w /workspace `
  uml2code-cli /workspace/config.json
```

Notes:
- The UML files and `config.json` must be inside the mounted folder.
- On Windows/macOS with Docker Desktop, make sure the folder is shared with Docker.
- On ARM machines, the image must be built for the local architecture (default `docker build` handles this).

## Documentation (HTML)

The image can serve the HTML documentation bundled in `documents/` (or `documents/documentation/` if present).
Place your main file at `documents/index.html` (or `documents/documentation/index.html`), then run:

```bash
docker run --rm -p 5555:5555 uml2code-cli docs
```

Open `http://127.0.0.1:5555` in your browser.

Optional port override:

```bash
DOCS_PORT=5555 docker run --rm -p 5555:5555 uml2code-cli docs
```

Shortcut:

```bash
chmod +x bin/uml2code
bin/uml2code config.json
```

## Validate config only

```bash
bin/uml2code config.json --validate
```

## AI mode

AI is available with `pipeline.mode=class_plus_sequence_ia`.

You must also set `ai.user_key_id` in the config and pass the key as an env var.

Example with Gemini:

```bash
GEMINI_API_KEY=... bin/uml2code config.json
```

Example with Claude:

```bash
ANTHROPIC_API_KEY=... bin/uml2code config.json
```

## config.json format

See `config_schema_v1.json` for the full schema. The config is resolved relative to the config file location.

Required top level blocks:

- `meta`: project metadata
- `inputs`: input files
- `pipeline`: execution mode

Optional blocks:

- `ai`: enable AI pipeline
- `spring`, `fastapi`, `laravel`, `nestjs`, `dart`, `fiber`: stack-specific options

### Minimal example (class only)

```json
{
  "meta": {
    "schema_version": "1.0",
    "project_name": "demo",
    "stack": "spring",
    "output_dir": "output"
  },
  "inputs": {
    "class_diagram_path": "datas/my_class.drawio"
  },
  "pipeline": {
    "mode": "class_only",
    "overwrite_strategy": "backup"
  }
}
```

### AI example (class + sequence)

```json
{
  "meta": {
    "schema_version": "1.0",
    "project_name": "demo",
    "stack": "spring",
    "output_dir": "output"
  },
  "inputs": {
    "class_diagram_path": "datas/my_class.drawio",
    "sequence_diagram_path": "datas/my_sequence.drawio"
  },
  "pipeline": {
    "mode": "class_plus_sequence_ia",
    "overwrite_strategy": "backup"
  },
  "ai": {
    "enabled": true,
    "provider": "gemini",
    "model": "gemini-1.5-pro-latest",
    "max_tokens": 32768,
    "timeout_seconds": 300,
    "user_key_id": "GEMINI_API_KEY"
  }
}
```

### Field summary

- `meta.project_name`: output project name.
- `meta.stack`: one of `fastapi`, `spring`, `laravel`, `dart`, `nestjs`, `fiber`.
- `meta.output_dir`: output folder under the workspace.
- `inputs.class_diagram_path`: required drawio for classes.
- `inputs.sequence_diagram_path`: required when `pipeline.mode=class_plus_sequence_ia`.
- `pipeline.mode`: `class_only` or `class_plus_sequence_ia`.
- `pipeline.overwrite_strategy`: `none`, `backup`, or `overwrite`.
- `ai.enabled`: enable AI step (requires `class_plus_sequence_ia`).
- `ai.provider`: `gemini` or `claude`.
- `ai.user_key_id`: name of the env var that holds the API key.

Defaults for stack options are set in `uml2code_config.py` (`apply_defaults`).
