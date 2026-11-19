# hpc-containers

Immagini container per il cluster HPC, costruite in CI e distribuite in due formati:

| Formato | Dove | Per chi |
|---|---|---|
| OCI (Docker) | `ghcr.io/ilbenni/<immagine>:<tag>` | podman/docker sulla workstation, cloud, Kubernetes |
| SIF (Apptainer) | `oras://ghcr.io/ilbenni/<immagine>-sif:<tag>` | cluster HPC, pronto all'uso |

Sui nodi del cluster serve solo Apptainer.

## Immagini disponibili

| Immagine | Versione | Note |
|---|---|---|
| [`blender`](images/blender) | vedi [`VERSION`](images/blender/VERSION) | binario ufficiale blender.org, Cycles CPU/CUDA/OptiX |

## Tag

- `<versione>-<build>` (es. `5.2.2-7`): **immutabile**, da usare per riproducibilità.
- `<versione>` (es. `5.2.2`): punta all'ultima build di quella versione.

## Uso sul cluster

```bash
# SIF già pronto
apptainer pull blender.sif oras://ghcr.io/ilbenni/blender-sif:5.2.2

# oppure dall'immagine OCI (Apptainer la converte)
apptainer pull blender.sif docker://ghcr.io/ilbenni/blender:5.2.2

# con GPU NVIDIA: --nv monta nel container il driver dell'host
apptainer exec --nv blender.sif blender -b --version
```

Esempio di job array Slurm (un frame per task): [`examples/slurm/blender-render.sbatch`](examples/slurm/blender-render.sbatch).

### Verifica GPU

```bash
apptainer exec --nv blender.sif nvidia-smi
apptainer exec --nv blender.sif blender -b --python-expr \
  "import bpy; p=bpy.context.preferences.addons['cycles'].preferences; p.get_devices(); print([(d.name,d.type) for d in p.devices])"
```

Devono comparire dispositivi `CUDA` e `OPTIX`. Se manca `OPTIX`, controllare che
`libnvoptix.so.1` sia in `/etc/apptainer/nvliblist.conf`.

## Aggiungere o aggiornare un'immagine

Ogni immagine è una cartella in `images/`:

```
images/<nome>/
  Dockerfile   # riceve --build-arg VERSION
  VERSION      # una riga, es. 5.2.2
  test.sh      # opzionale: smoke test eseguito dentro il container
```

- **Aggiornare** = cambiare `VERSION` e aprire una PR.
- Su **pull request** la CI costruisce e testa, senza pubblicare.
- Al **merge su `main`** la CI costruisce, testa, pubblica l'OCI, converte in SIF e pubblica il SIF.
- Rebuild manuale: *Actions → build-images → Run workflow* (nome immagine o `all`).

Build in locale (serve docker):

```bash
ci/build.sh blender            # build + test, nessun push
```

Dependabot (`.github/dependabot.yml`) controlla ogni lunedì le versioni delle action e delle
immagini base e apre una PR quando c'è un aggiornamento.

Se cambia la pipeline (`ci/` o il workflow) vengono ricostruite tutte le immagini.

## Struttura

```
images/                  una cartella per immagine
ci/build.sh              build, test, push OCI, conversione e push SIF
ci/changed-images.sh     quali immagini sono cambiate
.github/workflows/       pipeline GitHub Actions
examples/slurm/          job di esempio
```

La logica sta negli script in `ci/`, il workflow li chiama soltanto: per migrare a
Forgejo Actions basta spostare il workflow in `.forgejo/workflows/`, cambiare `runs-on`
e il `REGISTRY`.
