# phyloTreeViz-WDL
A WDL workflow for automated rendering of phylogenetic trees from Newick files using ETE3, supporting customizable image format, font size & resolution in a reproducible Docker environment.


**Phylogenetic tree visualization workflow using WDL & ETE3**

This WDL-based workflow renders phylogenetic trees from Newick format files using the powerful ETE3 Python library. It supports rendering multiple trees in parallel, with customizable font size, width & image format.

---

## Features

- Supports batch rendering of `.nwk` Newick files
- Generates high-resolution tree images (PNG, SVG)
- Customizable width & font size
- Clean render logs for debugging
- Dockerized for reproducibility

---

## Requirements

- [Cromwell](https://github.com/broadinstitute/cromwell)
- Docker (or Singularity for HPC environments)
- WDL 1.0 compatible runner
- Input Newick trees

---

## Quickstart

### 1. Clone this repository

```bash
git clone https://github.com/gmboowa/phyloTreeViz-WDL.git
cd phyloTreeViz-WDL
```

### 2. Prepare input JSON

Save this as `inputs/example_inputs.json`:

```json
{
  "TREE_VISUALIZATION.input_trees": [
    "test_data/core_core_genes.nwk",
    "test_data/accessory_accessory_genes.nwk"
  ],
  "TREE_VISUALIZATION.width": 1200,
  "TREE_VISUALIZATION.image_format": "png",
  "TREE_VISUALIZATION.font_size": 8
}
```

### 3. Run the workflow with Cromwell

```bash
java -jar cromwell.jar run phyloTreeViz-WDL.wdl -i inputs.json
```

---

## Output

Each tree will result in:
- A rendered image (`phylogenetic_tree_<input>.png`)
- A detailed log file (`render_<input>.log`)

They will be found in the `final_phylogenetic_tree_image/` directory per task.

---

## Docker image

The workflow uses the pre-built Docker image:
```
gmboowa/ete3-render:1.14
```

This image comes with:
- Python 3
- ETE3
- All dependencies pre-installed

> You can build your own using the included `Dockerfile` if needed.

---

## Repository structure

```
.
├── workflows/
│   └── TREE_VISUALIZATION.wdl         # Main WDL workflow
├── inputs/
│   └── example_inputs.json            # Example JSON input
├── test_data/
│   ├── core_core_genes.nwk            # Sample Newick trees
│   └── accessory_accessory_genes.nwk
├── docker/
│   └── Dockerfile                     # (Optional) Docker image build
├── LICENSE
└── README.md
```

---

## License

MIT License – see `LICENSE` file for details.

---

## Acknowledgments


Uses [ETE3](http://etetoolkit.org/) for tree rendering.

---

## Troubleshooting

- **Missing Docker?** Ensure Docker is installed and accessible to Cromwell.
- **Tree not rendered?** Check logs in `render_*.log` for Python errors.
- **No output image?** Ensure input `.nwk` file is valid and has correct format.

---

## Contact

For questions, suggestions, or contributions, feel free to open an issue or pull request.

