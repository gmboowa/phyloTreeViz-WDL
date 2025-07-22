version 1.0

task VALIDATE_AND_RENDER {
  input {
    File input_tree
    Int width = 1200
    String image_format = "png"
    Int font_size = 8
    Boolean show_scale = true
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
from ete3 import Tree, TreeStyle, TextFace, NodeStyle

def main():
    try:
        print("[DEBUG] Starting tree rendering")
        input_path = "/tmp/inputs/input.nwk"
        output_path = "/tmp/outputs/tree.png"
        
        if not os.path.exists(input_path):
            raise FileNotFoundError(f"Input file missing: {input_path}")
            
        t = Tree(input_path, format=1)
        print(f"[SUCCESS] Loaded tree with {len(t)} leaves")
        
        ts = TreeStyle()
        ts.show_scale = ~{true="True" false="False" show_scale}
        ts.scale_length = 0.1
        ts.mode = "r"
        ts.rotation = 0
        ts.branch_vertical_margin = 15
        ts.show_leaf_name = True
        ts.min_leaf_separation = 5
        ts.allow_face_overlap = True
        ts.complete_branch_lines_when_necessary = True
        ts.root_opening_factor = 0.5
        ts.margin_left = 50
        ts.margin_right = 50
        ts.margin_top = 50
        ts.margin_bottom = 50

        for node in t.traverse():
            if not node.is_leaf():
                ns = NodeStyle()
                ns["size"] = 0
                if hasattr(node, 'support'):
                    support_value = node.support
                    if support_value is not None:
                        support_text = f"{support_value:.0%}"
                        support_face = TextFace(support_text, 
                                             fsize=~{font_size}, 
                                             fgcolor="black",
                                             bold=True)
                        support_face.margin_right = 10
                        support_face.margin_left = 10
                        node.add_face(support_face, column=0, position="branch-top")
                node.set_style(ns)

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

    # Handle outputs
    if [[ -f "/tmp/outputs/tree.png" ]]; then
      mkdir -p final_phylogenetic_tree_image
      cp "/tmp/outputs/tree.png" "final_phylogenetic_tree_image/phylogenetic_tree_~{basename(input_tree)}.~{image_format}"
      cp "/tmp/outputs/render.log" "./render_~{basename(input_tree)}.log"
      exit 0
    else
      mkdir -p final_phylogenetic_tree_image
      echo "Rendering failed" > "error_~{basename(input_tree)}.log"
      cp "/tmp/outputs/render.log" "./render_~{basename(input_tree)}.log"
      exit 1
    fi
  >>>

  runtime {
    docker: "gmboowa/ete3-render:1.14"
    memory: "2 GB"
    cpu: 1
    continueOnReturnCode: true
  }

  output {
    File final_image = "final_phylogenetic_tree_image/phylogenetic_tree_~{basename(input_tree)}.~{image_format}"
    File render_log = "render_~{basename(input_tree)}.log"
  }
}

workflow TREE_VISUALIZATION {
  input {
    Array[File] input_trees
    Int width = 1200
    String image_format = "png"
    Int font_size = 8
    Boolean show_scale = true
  }

  scatter (tree in input_trees) {
    call VALIDATE_AND_RENDER {
      input:
        input_tree = tree,
        width = width,
        image_format = image_format,
        font_size = font_size,
        show_scale = show_scale
    }
  }

  output {
    Array[File] final_images = VALIDATE_AND_RENDER.final_image
    Array[File] render_logs = VALIDATE_AND_RENDER.render_log
  }
}
