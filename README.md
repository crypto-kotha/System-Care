# Advanced System Care

The **Advanced System Care** script is a comprehensive Windows system optimization tool. It automates various tasks to enhance system performance, clean up unnecessary files, and optimize disk usage. Below is a detailed overview of its functionalities:

---

## Features

### 1. **Automatic ScheduleTask Automation**
   - Creates a **Task Scheduler** entry to run the script **daily at 12:01 AM**.  
   - Ensures consistent system maintenance without requiring user intervention.

### 2. **Junk File Cleanup**
   - Removes unnecessary files to free up disk space, including:
     - Clears the `%temp%` folder.
     - Deletes error reports (`WER` files).
     - Removes thumbnail caches.
     - Cleans Windows Update temporary files.

### 3. **Disk Optimization**
   - **For SSDs:**
     - Runs the **TRIM** command to improve performance and extend lifespan.
   - **For HDDs:**
     - Defragments the disk to optimize file storage.
     - Compresses specific folders using **NTFS compression** to save disk space.

### 4. **Service Management**
   - Disables unnecessary Windows services to improve performance, including:
     - Diagnostic Tracking Service (`DiagTrack`).
     - Windows Search (`WSearch`).
     - Superfetch/Prefetch (`SysMain`).
   - Disables **GameDVR** and tweaks other Xbox-related features in the registry.

### 5. **System Performance Enhancements**
   - Optimizes network performance by modifying **TCP settings** (e.g., autotuning).
   - Adjusts Windows settings to reduce background processes and improve responsiveness.

---

## Instructions

### 1. **Download the Script**
   - Copy the script into a new `.ps1` file.
   - For example, save it as `optimize.ps1` on your desktop or a folder of your choice.

### 2. **Set PowerShell Execution Policy** (if required)
   If script execution is disabled on your system, follow these steps:

   1. **Open PowerShell as Administrator**:
      - Press `Win + X` and select **Windows PowerShell (Admin)**.

   2. **Allow Script Execution**:
      - Run the following command to enable script execution:
        ```powershell
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
        ```
        This command allows locally created scripts to run but requires downloaded scripts to be signed by a trusted publisher.

   3. **Confirm the Change**:
      - When prompted, type `Y` to confirm the change.

### 3. **Run the Script Manually**
   To run the script manually, follow these steps:

   1. **Navigate to the Script's Folder**:
      - Use the `cd` (change directory) command to navigate to the folder where the script is saved.
        ```powershell
        cd "C:\Users\Set_Your_Username\Desktop"
        ```

   2. **Execute the Script**:
      - Run the script with the following command:
        ```powershell
        .\optimize.ps1
        ```
      - The script will execute, performing disk cleanup, service management, and system optimizations.

### 4. **Set Up the Script to Run Automatically (Optional)**
   To schedule the script to run automatically (e.g., daily at 12:01 AM):

   1. **Open Task Scheduler**:
      - Press `Win + R`, type `taskschd.msc`, and press **Enter**.

   2. **Create a New Task**:
      - In **Task Scheduler**, click **Create Task** in the right panel.

   3. **General Tab**:
      - Name the task (e.g., "System Optimization").
      - Check **Run with highest privileges** to ensure the task has sufficient permissions.

   4. **Triggers Tab**:
      - Click **New** and set the trigger to **Daily** at **12:01 AM** (or your preferred time).

   5. **Actions Tab**:
      - Click **New**, then set the action to **Start a Program**.
      - In the **Program/script** field, enter `powershell.exe`.
      - In the **Add arguments** field, enter:
        ```powershell
        -ExecutionPolicy Bypass -File "C:\Path\To\Script\optimize.ps1"
        ```
        Replace `C:\Path\To\Script\optimize.ps1` with the actual path to your script.

   6. **Save the Task**:
      - Click **OK** to save and activate the task.

---

## Troubleshooting

- **Script Execution Blocked**: If you encounter errors related to script execution, ensure that the execution policy is set to `RemoteSigned` or `Unrestricted`.
- **Permissions Issues**: Ensure you are running PowerShell as Administrator to avoid permissions errors.

---

## Who Should Use This Script?

**Advanced System Care** ideal for:
- **Tech-savvy users** who wish to automate regular system maintenance tasks.
- **System administrators** seeking a customizable optimization tool for multiple machines.
- **Gamers and power users** looking to optimize their systems for performance and efficiency.

---
