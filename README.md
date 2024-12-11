# What This Script Can Do

This PowerShell script is a comprehensive Windows system optimization tool. It automates various tasks to improve system performance, clean up unnecessary files, and optimize disk usage. Below is a detailed list of its functionalities:

---

## Prerequisites

Before running the script, ensure the following:

1. **Administrator Privileges**: The script needs administrative rights to perform system-level tasks such as disabling services and cleaning up junk files.
2. **PowerShell Version**: Ensure you are using a compatible version of PowerShell (PowerShell 5.1 or later is recommended).
3. **Execution Policy**: PowerShell may block script execution by default. You may need to adjust the execution policy to allow running scripts.

---

## Step-by-Step Instructions

### 1. **Download the Script**
   - Copy the script into a new `.ps1` file.  
   - For example, save it as `SystemOptimization.ps1` on your desktop or a folder of your choice.

### 2. **Set PowerShell Execution Policy** (if required)
   If you haven't already allowed script execution, follow these steps:

   1. Open **PowerShell** as **Administrator**:
      - Press `Win + X` and select **Windows PowerShell (Admin)**.
   
   2. To allow script execution, run the following command:
      ```powershell
      Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
      ```
      - This will allow running locally created scripts, but will require downloaded scripts to be signed by a trusted publisher.

   3. When prompted, type `Y` to confirm the change.

### 3. **Run the Script Manually**
   To run the script manually:

   1. **Navigate to the script's folder** in PowerShell:
      - Use the `cd` (change directory) command to go to the folder where the script is saved.
      ```powershell
      cd "C:\Path\To\Script"
      ```

   2. **Run the script** by typing the following command and pressing **Enter**:
      ```powershell
      .\SystemOptimization.ps1
      ```
   - The script will execute, performing various tasks such as disk cleanup, service management, and system optimizations.
   
### 4. **Set Up the Script to Run Automatically (Optional)**
   If you want the script to run automatically at a scheduled time (e.g., daily at 12:01 AM):

   1. Open **Task Scheduler**:
      - Press `Win + R`, type `taskschd.msc`, and press **Enter**.
   
   2. In **Task Scheduler**, click on **Create Task** in the right-hand panel.
   
   3. In the **General** tab:
      - Name your task (e.g., "System Optimization").
      - Check **Run with highest privileges**.

   4. In the **Triggers** tab:
      - Click **New**, and set the trigger to **Daily** at **12:01 AM** (or your desired time).
   
   5. In the **Actions** tab:
      - Click **New**, and set the action to **Start a Program**.
      - In the **Program/script** field, type `powershell.exe`.
      - In the **Add arguments** field, enter:
        ```powershell
        -ExecutionPolicy Bypass -File "C:\Path\To\Script\SystemOptimization.ps1"
        ```
      - Replace `C:\Path\To\Script\SystemOptimization.ps1` with the actual path to your script.

   6. Click **OK** to save the task.

---

## Troubleshooting

- **Script Execution Blocked**: If you encounter errors related to script execution, ensure that the execution policy is set to `RemoteSigned` or `Unrestricted`.
- **Permissions Issue**: Make sure you are running PowerShell as Administrator when executing the script.

---

## 1. Task Automation  
- Creates a **Task Scheduler** entry to run the script **daily at 12:01 AM**.  
- Ensures consistent system maintenance without user intervention.  

---

## 2. System Information Display  
- Displays key system information, such as:  
  - Operating System details.  
  - System architecture (e.g., x64 or x86).  
  - Total RAM, CPU usage, and more.  

---

## 3. Junk File Cleanup  
- Removes unnecessary files to free up disk space:  
  - Clears the `%temp%` folder.  
  - Deletes error reports (`WER` files).  
  - Removes thumbnail caches.  
  - Cleans Windows Update temporary files.  

---

## 4. Disk Optimization  
- **For SSDs:**  
  - Runs the **TRIM** command for better performance and longer lifespan.  
- **For HDDs:**  
  - Defragments the disk to optimize file storage.  
- Compresses specific folders using **NTFS compression** to save disk space.  

---

## 5. Service Management  
- Disables unnecessary Windows services to improve performance:  
  - Diagnostic Tracking Service (`DiagTrack`).  
  - Windows Search (`WSearch`).  
  - Superfetch/Prefetch (`SysMain`).  
- Tweaks Xbox-related features by disabling **GameDVR** and other registry entries.  

---

## 6. System Performance Enhancements  
- Optimizes network performance by modifying **TCP settings** (e.g., autotuning).  
- Adjusts Windows settings to reduce background processes.  

---

## 7. Logging and Error Handling  
- Logs script actions to track what changes were made.  
- Implements **error-handling** mechanisms to ensure the script continues running if one section encounters an error.  

---

## 8. Safe Execution  
- Checks for **administrator privileges** before running.  
- Skips operations that could harm the system if run without elevated permissions.  

---

## Who Should Use This Script?  
This script is ideal for:  
- **Tech-savvy users** who want to automate system maintenance.  
- **System administrators** looking for a customizable optimization tool.  
- **Gamers and power users** who want to maximize system performance.  

---


