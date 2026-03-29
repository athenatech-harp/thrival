# Raspberry Pi 5 Local LLM Setup Guide
## Running a Private AI Model on Your Raspberry Pi

---

## What You're Building

By the end of this guide, you'll have a **local AI language model** running on your Raspberry Pi that can:
- Analyze wellness tracking data
- Identify patterns in mood, sleep, and anxiety
- Generate insights and recommendations
- Run completely offline and private (no cloud required)

**Time required:** 2-3 hours for complete setup

**What you'll learn:**
- Linux command line basics
- Installing and configuring software
- Running AI models locally
- Setting up API servers
- Troubleshooting technical issues

---

## Prerequisites

**What you need:**
- ✅ Raspberry Pi 5 (16GB RAM) - already set up
- ✅ Keyboard, mouse, monitor connected
- ✅ Raspberry Pi OS installed and running
- ✅ Internet connection (WiFi or Ethernet)
- ✅ Power supply connected

**Before starting:**
1. Boot up your Pi
2. Open the Terminal application (black screen icon)
3. Make sure you're connected to WiFi

---

## Part 1: System Preparation (20 minutes)

### Step 1: Update Your System

This ensures you have the latest software versions.

**In the Terminal, type these commands one at a time:**

```bash
sudo apt update
```
*(This checks for available updates - will take 1-2 minutes)*

```bash
sudo apt upgrade -y
```
*(This installs updates - will take 5-10 minutes)*

**What's happening:** `apt` is the package manager for Linux. `sudo` means "run as administrator". The `-y` flag means "yes to all prompts".

---

### Step 2: Install Required Tools

**Type this command:**

```bash
sudo apt install -y python3-pip python3-venv git curl
```

**What each tool does:**
- `python3-pip` - Python package installer
- `python3-venv` - Creates isolated Python environments
- `git` - Version control (for downloading code)
- `curl` - Downloads files from the internet

**Expected result:** You'll see text scrolling as each tool installs. Takes 2-3 minutes.

---

### Step 3: Check Your RAM

Let's verify you have 16GB available.

**Type:**

```bash
free -h
```

**What to look for:**
- Look at the line that says "Mem:"
- The "total" column should show around **15Gi** (16GB minus system overhead)

**Example output:**
```
              total        used        free      shared  buff/cache   available
Mem:           15Gi       2.1Gi       11Gi       142Mi       2.0Gi        12Gi
```

✅ If you see ~15Gi total, you're good to proceed!

---

## Part 2: Install Ollama (AI Model Runner) (15 minutes)

**Ollama** is software that makes it easy to download and run AI models.

### Step 1: Download and Install Ollama

**Type this command:**

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**What's happening:** This downloads and runs an installation script from Ollama's website.

**Expected result:** 
- Will take 3-5 minutes
- You'll see progress messages
- Should end with "Ollama is now installed!"

---

### Step 2: Verify Ollama Installed

**Type:**

```bash
ollama --version
```

**Expected result:** Should show something like `ollama version 0.x.x`

✅ If you see a version number, Ollama is installed correctly!

---

### Step 3: Start Ollama Service

**Type:**

```bash
sudo systemctl start ollama
```

**Then check it's running:**

```bash
sudo systemctl status ollama
```

**What to look for:**
- Should say "active (running)" in green
- Press `q` to exit this view

---

## Part 3: Download an AI Model (30 minutes)

Now we'll download a language model. We're using **Llama 3.2 3B** - small enough to run fast on Pi, smart enough to be useful.

### Step 1: Pull the Model

**Type:**

```bash
ollama pull llama3.2:3b
```

**What's happening:**
- Downloads a 2GB AI model
- Will take 10-30 minutes depending on internet speed
- You'll see a progress bar

**⏳ This is a good time to take a break!**

---

### Step 2: Test the Model

Once download completes, let's verify it works.

**Type:**

```bash
ollama run llama3.2:3b
```

**What happens:**
- Model loads into memory (takes 10-20 seconds)
- You'll see a prompt: `>>>`
- You can now chat with the AI!

**Try typing:**
```
Hello! Can you analyze patterns in data?
```

**Expected result:** The AI should respond in a few seconds.

**To exit:** Type `/bye` and press Enter

✅ If the AI responded, your local LLM is working!

---

## Part 4: Set Up API Access (45 minutes)

Now we'll create a way for other apps (like your iPhone wellness tracker) to talk to this AI.

### Step 1: Create a Project Directory

**Type these commands:**

```bash
cd ~
mkdir thrival-llm-server
cd thrival-llm-server
```

**What this does:**
- `cd ~` - Go to your home directory
- `mkdir` - Create a new folder
- `cd thrival-llm-server` - Enter that folder

---

### Step 2: Create a Python Virtual Environment

**Type:**

```bash
python3 -m venv venv
```

**Wait 30 seconds for it to create the environment.**

**Then activate it:**

```bash
source venv/bin/activate
```

**What to look for:** Your prompt should now start with `(venv)` - this means the virtual environment is active.

---

### Step 3: Install Python Packages

**Type:**

```bash
pip install flask requests
```

**What these do:**
- `flask` - Web framework for creating APIs
- `requests` - Makes it easy to talk to Ollama

**Takes 1-2 minutes to install.**

---

### Step 4: Create the API Server Code

We'll create a Python file that handles requests from the iPhone app.

**Type:**

```bash
nano api_server.py
```

**This opens a text editor.** Now copy and paste this code:

```python
from flask import Flask, request, jsonify
import requests
import json

app = Flask(__name__)

# Ollama API endpoint
OLLAMA_URL = "http://localhost:11434/api/generate"

@app.route('/analyze', methods=['POST'])
def analyze_wellness_data():
    """
    Receives wellness tracking data and returns AI-generated insights
    """
    try:
        # Get data from the request
        data = request.get_json()
        
        # Extract tracking information
        entries = data.get('entries', [])
        
        if not entries:
            return jsonify({'error': 'No entries provided'}), 400
        
        # Build a prompt for the AI
        prompt = build_analysis_prompt(entries)
        
        # Send to Ollama
        response = requests.post(
            OLLAMA_URL,
            json={
                "model": "llama3.2:3b",
                "prompt": prompt,
                "stream": False
            }
        )
        
        if response.status_code == 200:
            result = response.json()
            insight = result.get('response', '')
            
            return jsonify({
                'insight': insight,
                'status': 'success'
            })
        else:
            return jsonify({'error': 'Ollama request failed'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def build_analysis_prompt(entries):
    """
    Creates a prompt for the LLM based on wellness data
    """
    # Format the entries into a readable summary
    summary = "Wellness Tracking Data:\n\n"
    
    for i, entry in enumerate(entries[-7:], 1):  # Last 7 days
        summary += f"Day {i}:\n"
        summary += f"  - Date: {entry.get('date', 'N/A')}\n"
        summary += f"  - Sleep: {entry.get('sleep_hours', 'N/A')} hours, quality {entry.get('sleep_quality', 'N/A')}/5\n"
        summary += f"  - Anxiety: Morning {entry.get('morning_anxiety', 'N/A')}/10, "
        summary += f"Afternoon {entry.get('afternoon_anxiety', 'N/A')}/10, "
        summary += f"Evening {entry.get('evening_anxiety', 'N/A')}/10\n"
        summary += f"  - Brain Fog: {entry.get('brain_fog', 'N/A')}/5\n"
        summary += f"  - Medications: {entry.get('medications', 'N/A')}\n"
        summary += f"  - Mood Notes: {entry.get('mood_notes', 'N/A')}\n\n"
    
    prompt = f"""{summary}

Based on this wellness tracking data, provide:

1. **Key Patterns**: What trends do you notice in sleep, anxiety, and functioning?

2. **Correlations**: Are there relationships between sleep quality and anxiety levels? Between medication timing and symptoms?

3. **Observations**: Any concerning trends or positive developments?

4. **Suggestions**: 1-2 small, specific habit adjustments that might help (be concrete and actionable).

Keep your response objective, non-judgmental, and focused on observable patterns. Do not provide medical advice - only data observations and general wellness suggestions."""

    return prompt


@app.route('/health', methods=['GET'])
def health_check():
    """
    Simple endpoint to check if the server is running
    """
    return jsonify({'status': 'healthy', 'message': 'LLM API server is running'})


if __name__ == '__main__':
    # Run on all network interfaces so iPhone can access it
    app.run(host='0.0.0.0', port=5000, debug=True)
```

**To save and exit nano:**
1. Press `Ctrl + X`
2. Press `Y` (for "yes, save")
3. Press `Enter` (to confirm filename)

---

### Step 5: Test the API Server

**Start the server:**

```bash
python api_server.py
```

**What you'll see:**
```
* Running on http://0.0.0.0:5000
* Restarting with stat
* Debugger is active!
```

**✅ The server is now running!**

**To test it's working,** open a new Terminal tab (Ctrl+Shift+T) and type:

```bash
curl http://localhost:5000/health
```

**Expected result:** Should return `{"status":"healthy","message":"LLM API server is running"}`

**To stop the server:** Press `Ctrl + C` in the terminal where it's running

---

## Part 5: Make It Run Automatically (30 minutes)

Right now, the server stops when you close the terminal. Let's make it run automatically on startup.

### Step 1: Create a Systemd Service File

**Type:**

```bash
sudo nano /etc/systemd/system/thrival-llm.service
```

**Paste this configuration:**

```ini
[Unit]
Description=Thrival LLM API Server
After=network.target ollama.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/thrival-llm-server
Environment="PATH=/home/pi/thrival-llm-server/venv/bin"
ExecStart=/home/pi/thrival-llm-server/venv/bin/python api_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Save and exit:** `Ctrl+X`, then `Y`, then `Enter`

---

### Step 2: Enable and Start the Service

**Type these commands:**

```bash
sudo systemctl daemon-reload
```
*(Tells the system about the new service)*

```bash
sudo systemctl enable thrival-llm.service
```
*(Makes it start on boot)*

```bash
sudo systemctl start thrival-llm.service
```
*(Starts it right now)*

---

### Step 3: Check Service Status

**Type:**

```bash
sudo systemctl status thrival-llm.service
```

**What to look for:**
- Should say "active (running)" in green
- Press `q` to exit

✅ **Your LLM server is now running automatically!**

---

## Part 6: Find Your Pi's IP Address (5 minutes)

The iPhone app needs to know where to send requests.

**Type:**

```bash
hostname -I
```

**Example output:** `192.168.1.147`

**✅ Write down this IP address!** You'll need it for the iPhone app configuration.

The API endpoint will be: `http://YOUR_IP_ADDRESS:5000/analyze`

Example: `http://192.168.1.147:5000/analyze`

---

## Testing Your Complete Setup

### Test 1: Health Check

**From any computer on your home network, open a browser and go to:**

```
http://YOUR_PI_IP:5000/health
```

**Expected result:** Should show the health status message

---

### Test 2: Analysis Request

**In Terminal on the Pi, type:**

```bash
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "entries": [
      {
        "date": "2025-03-29",
        "sleep_hours": 6,
        "sleep_quality": 3,
        "morning_anxiety": 7,
        "afternoon_anxiety": 8,
        "evening_anxiety": 6,
        "brain_fog": 4,
        "medications": "Concerta 18mg at 7am",
        "mood_notes": "Feeling overwhelmed"
      }
    ]
  }'
```

**Expected result:** After 10-30 seconds, you should get an AI-generated insight analyzing the data.

✅ **If you get an insight, everything is working!**

---

## Troubleshooting Guide

### Problem: Ollama won't start

**Solution:**
```bash
sudo systemctl restart ollama
sudo systemctl status ollama
```

### Problem: Model won't download

**Check internet connection:**
```bash
ping -c 4 google.com
```

**Try download again:**
```bash
ollama pull llama3.2:3b
```

### Problem: API server won't start

**Check if port is already in use:**
```bash
sudo lsof -i :5000
```

**View server logs:**
```bash
journalctl -u thrival-llm.service -f
```

### Problem: Can't access from iPhone

**Make sure both devices are on the same WiFi network**

**Check firewall isn't blocking:**
```bash
sudo ufw status
```

**If active, allow port 5000:**
```bash
sudo ufw allow 5000
```

---

## What You've Accomplished

✅ Installed and configured a Raspberry Pi as an AI server  
✅ Downloaded and tested a local language model  
✅ Created an API that other apps can use  
✅ Set up automatic startup so it runs 24/7  
✅ Learned Linux command line basics  
✅ Built a completely private AI system  

**Your Pi is now:**
- Running a 3 billion parameter AI model
- Accessible from your home network
- Processing wellness data locally
- Providing intelligent insights
- Completely private (no cloud required)

---

## Next Steps

1. **Tell your mom the Pi IP address** so she can configure the iPhone app
2. **Monitor system resources** to make sure it's running smoothly:
   ```bash
   htop
   ```
   (Press `q` to exit)

3. **Check logs if needed:**
   ```bash
   journalctl -u thrival-llm.service -n 50
   ```

4. **Later: Try other models** if you want more power:
   ```bash
   ollama pull mistral:7b
   ```

---

## Questions to Explore

Now that you have this working, think about:

- **How does the AI model actually work?** (Neural networks, transformers)
- **What makes this "3 billion parameter" model special?**
- **How much power does the Pi use running 24/7?** (Hint: About 15 watts)
- **Could you run multiple models at once?**
- **What other applications could use this local AI?**

---

## Additional Resources

- **Ollama Documentation:** https://ollama.com/docs
- **Raspberry Pi Projects:** https://projects.raspberrypi.org
- **Flask API Tutorial:** https://flask.palletsprojects.com
- **Linux Command Line Guide:** https://ubuntu.com/tutorials/command-line-for-beginners

---

**Great job!** You've built a sophisticated AI system from scratch. This is the same type of infrastructure that companies use, just running on a tiny computer in your home.

**Questions?** Ask your mom to reach out to Claude for help troubleshooting any issues.
