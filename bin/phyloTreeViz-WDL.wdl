version 1.0

workflow TREE_VISUALIZATION {
  input {
    Array[File] input_trees
    Int width = 1000
    String? image_format = "png"
    Int font_size = 12
  }

  scatter (tree in input_trees) {
    call VALIDATE_AND_RENDER {
      input:
        input_tree = tree,
        width = width,
        image_format = select_first([image_format, "png"]),
        font_size = font_size
    }
  }

  output {
    Array[File?] rendered_images = VALIDATE_AND_RENDER.final_image
    Array[File] render_logs = VALIDATE_AND_RENDER.render_log
  }
}

task VALIDATE_AND_RENDER {
  input {
    File input_tree
    Int width
    String image_format
    Int font_size
    
    # Add continueOnReturnCode to handle potential non-zero exit codes
    Int? continueOnReturnCode = 1
  }

  command <<<
    # Create all directories first
    mkdir -p /tmp/inputs /tmp/outputs final_phylogenetic_tree_image
    
    # Get the basename of the input file
    INPUT_BASENAME=$(basename "~{input_tree}")
    
    # Copy input file
    if [[ ! -f "~{input_tree}" ]]; then
      echo "Input file ~{input_tree} not found!" >&2
      exit 1
    fi
    cp "~{input_tree}" /tmp/inputs/input.nwk
    
    # Execute Python script
    python3 <<'PYTHON_SCRIPT' > /tmp/outputs/render.log 2>&1
import os
import sys
import traceback
from ete3 import Tree, TreeStyle, TextFace

def main():
    try:
        print("[DEBUG] Starting tree rendering")
        input_path = "/tmp/inputs/input.nwk"
        output_path = f"/tmp/outputs/tree.png"  # Simplified output path
        
        if not os.path.exists(input_path):
            raise FileNotFoundError(f"Input file missing: {input_path}")
            
        t = Tree(input_path)
        print(f"[SUCCESS] Loaded tree with {len(t)} leaves")
        
        ts = TreeStyle()
        ts.show_scale = False
        ts.mode = "r"  # Rectangular mode
        ts.rotation = 0  # Standard left-to-right orientation
        ts.branch_vertical_margin = 15  # Space between branches
        ts.show_leaf_name = False  # We'll add them manually to control font size
        ts.min_leaf_separation = 5
        ts.allow_face_overlap = False
        ts.complete_branch_lines_when_necessary = True
        ts.root_opening_factor = 0.5  # Controls root spread
        ts.margin_left = 50  # Left margin
        ts.margin_right = 50  # Right margin
        ts.margin_top = 50  # Top margin
        ts.margin_bottom = 50  # Bottom margin

        # Add leaf names with controlled font size
        for leaf in t.iter_leaves():
            face = TextFace(leaf.name, fsize=~{font_size})
            leaf.add_face(face, column=0, position="branch-right")
        
        print(f"[DEBUG] Rendering to {output_path}")
        t.render(output_path, w=~{width}, units="px", tree_style=ts)
        
        if not os.path.exists(output_path):
            raise RuntimeError("Rendering completed but no output file created")
            
        print("[SUCCESS] Render completed")
        return 0
        
    except Exception as e:
        print(f"[ERROR] {traceback.format_exc()}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
PYTHON_SCRIPT

    # Handle outputs with new directory structure
    if [[ -f "/tmp/outputs/tree.png" ]]; then
      mkdir -p final_phylogenetic_tree_image
      cp "/tmp/outputs/tree.png" "final_phylogenetic_tree_image/phylogenetic_tree_${INPUT_BASENAME}.png"
      cp "/tmp/outputs/render.log" "./render_${INPUT_BASENAME}.log"
      exit 0
    else
      mkdir -p final_phylogenetic_tree_image
      echo "Rendering failed" > error_${INPUT_BASENAME}.log
      cp "/tmp/outputs/render.log" "./render_${INPUT_BASENAME}.log"
      exit 1
    fi
  >>>

  runtime {
    docker: "gmboowa/ete3-render:1.14"
    # Remove memory and cpu attributes if not supported by your local backend
  }

  output {
    File? final_image = "final_phylogenetic_tree_image/phylogenetic_tree_${basename(input_tree)}.~{image_format}"
    File render_log = "render_${basename(input_tree)}.log"
  }
}