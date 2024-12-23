# Adding Custom "Open with DigiDoc4" and "Open with VS Code" Actions in Nemo

## 1. Open Terminal

## 2. Create Custom Action Files

- **DigiDoc4 Action**:

  ```bash
  nano ~/.local/share/nemo/actions/digidoc4.nemo_action
  ```

- **Add this content to the file**:

  ```bash
        [Nemo Action]
        Name=Open with DigiDoc4
        Exec=/usr/bin/qdigidoc4 %F
        Comment=Open with DigiDoc4
        Selection=s
        Extensions=any;
  ```


- **VS Code Action**:

  ```bash
  nano ~/.local/share/nemo/actions/vscode.nemo_action
  ```

- **Add this content to the file**:

  ```bash
    [Nemo Action]
    Name=Open with VS Code
    Exec=/usr/bin/code %F
    Comment=Open with Visual Studio Code
    Selection=any
    Extensions=any;
  ```
  
## 3. Save and Restart Nemo

  ```bash
    nemo -q && nemo &
  ```