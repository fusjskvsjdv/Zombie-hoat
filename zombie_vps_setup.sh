#!/bin/bash
# سكريپت إعداد VPS Zombie لاستضافة البوتات والتطبيقات
# Zombie VPS Setup Script for Bot and App Hosting

echo "🧟 بدء إعداد Zombie VPS..."
echo "=================================="

# تحديث النظام
echo "📦 تحديث النظام..."
sudo apt update && sudo apt upgrade -y

# تثبيت Python والأدوات الأساسية
echo "🐍 تثبيت Python والأدوات..."
sudo apt install -y python3 python3-pip python3-venv python3-dev
sudo apt install -y git curl wget nano htop screen tmux
sudo apt install -y nginx supervisor redis-server postgresql

# تثبيت Node.js
echo "📦 تثبيت Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# إنشاء مستخدم zombie
echo "👤 إنشاء مستخدم zombie..."
sudo useradd -m -s /bin/bash zombie
sudo usermod -aG sudo zombie
echo "zombie:ZombieVPS2024!" | sudo chpasswd

# إعداد مجلدات العمل
echo "📁 إعداد مجلدات العمل..."
sudo mkdir -p /home/zombie/{bots,apps,logs,backups}
sudo mkdir -p /var/log/zombie
sudo chown -R zombie:zombie /home/zombie
sudo chown -R zombie:zombie /var/log/zombie

# تثبيت مكتبات Python الأساسية
echo "📚 تثبيت مكتبات Python..."
sudo pip3 install --upgrade pip
sudo pip3 install python-telegram-bot flask fastapi uvicorn gunicorn
sudo pip3 install requests httpx aiohttp
sudo pip3 install pycryptodome cryptography
sudo pip3 install psycopg2-binary redis pymongo
sudo pip3 install celery supervisor
sudo pip3 install docker docker-compose

# إعداد Nginx
echo "🌐 إعداد Nginx..."
sudo systemctl enable nginx
sudo systemctl start nginx

# إنشاء ملف إعداد Nginx للبوتات
sudo tee /etc/nginx/sites-available/zombie-bots > /dev/null <<EOF
server {
    listen 80;
    server_name zombie-vps.local *.zombie-vps.local;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /bot1/ {
        proxy_pass http://127.0.0.1:5001/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    
    location /bot2/ {
        proxy_pass http://127.0.0.1:5002/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    
    location /status {
        return 200 "Zombie VPS is running!";
        add_header Content-Type text/plain;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/zombie-bots /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# إعداد Supervisor للبوتات
echo "⚙️ إعداد Supervisor..."
sudo systemctl enable supervisor
sudo systemctl start supervisor

sudo tee /etc/supervisor/conf.d/zombie-bots.conf > /dev/null <<EOF
[group:zombie-bots]
programs=freefire-bot,zombie-manager

[program:freefire-bot]
command=/usr/bin/python3 /home/zombie/bots/freefire/webhook_bot.py
directory=/home/zombie/bots/freefire
user=zombie
autostart=true
autorestart=true
stderr_logfile=/var/log/zombie/freefire-bot.err.log
stdout_logfile=/var/log/zombie/freefire-bot.out.log
environment=PORT=5001

[program:zombie-manager]
command=/usr/bin/python3 /home/zombie/apps/zombie_manager.py
directory=/home/zombie/apps
user=zombie
autostart=true
autorestart=true
stderr_logfile=/var/log/zombie/manager.err.log
stdout_logfile=/var/log/zombie/manager.out.log
environment=PORT=5000
EOF

# إعداد قاعدة البيانات
echo "🗄️ إعداد قاعدة البيانات..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

sudo -u postgres createuser zombie
sudo -u postgres createdb zombie_db -O zombie
sudo -u postgres psql -c "ALTER USER zombie PASSWORD 'ZombieDB2024!';"

# إعداد Redis
echo "🔴 إعداد Redis..."
sudo systemctl enable redis-server
sudo systemctl start redis-server

# إنشاء سكريپت إدارة البوتات
echo "🤖 إنشاء سكريپت إدارة البوتات..."
sudo tee /home/zombie/bot_manager.sh > /dev/null <<'EOF'
#!/bin/bash
# Zombie Bot Manager

case "$1" in
    start)
        echo "🚀 بدء تشغيل جميع البوتات..."
        sudo supervisorctl start zombie-bots:*
        ;;
    stop)
        echo "🛑 إيقاف جميع البوتات..."
        sudo supervisorctl stop zombie-bots:*
        ;;
    restart)
        echo "🔄 إعادة تشغيل جميع البوتات..."
        sudo supervisorctl restart zombie-bots:*
        ;;
    status)
        echo "📊 حالة البوتات:"
        sudo supervisorctl status zombie-bots:*
        ;;
    logs)
        echo "📋 سجلات البوتات:"
        tail -f /var/log/zombie/*.log
        ;;
    deploy)
        echo "🚀 نشر بوت جديد..."
        if [ -z "$2" ]; then
            echo "❌ يجب تحديد اسم البوت"
            echo "الاستخدام: $0 deploy <bot_name>"
            exit 1
        fi
        
        BOT_NAME="$2"
        BOT_DIR="/home/zombie/bots/$BOT_NAME"
        
        if [ ! -d "$BOT_DIR" ]; then
            echo "❌ مجلد البوت غير موجود: $BOT_DIR"
            exit 1
        fi
        
        echo "📦 نشر البوت: $BOT_NAME"
        cd "$BOT_DIR"
        
        # تثبيت المتطلبات
        if [ -f "requirements.txt" ]; then
            pip3 install -r requirements.txt
        fi
        
        # إعادة تشغيل البوت
        sudo supervisorctl restart "zombie-bots:$BOT_NAME"
        echo "✅ تم نشر البوت بنجاح!"
        ;;
    *)
        echo "🧟 Zombie Bot Manager"
        echo "الاستخدام: $0 {start|stop|restart|status|logs|deploy <bot_name>}"
        echo ""
        echo "الأوامر المتاحة:"
        echo "  start   - بدء تشغيل جميع البوتات"
        echo "  stop    - إيقاف جميع البوتات"
        echo "  restart - إعادة تشغيل جميع البوتات"
        echo "  status  - عرض حالة البوتات"
        echo "  logs    - عرض سجلات البوتات"
        echo "  deploy  - نشر بوت جديد"
        ;;
esac
EOF

sudo chmod +x /home/zombie/bot_manager.sh
sudo ln -sf /home/zombie/bot_manager.sh /usr/local/bin/zombie

# إنشاء تطبيق إدارة Zombie
echo "🎮 إنشاء تطبيق إدارة Zombie..."
sudo tee /home/zombie/apps/zombie_manager.py > /dev/null <<'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Zombie VPS Manager
مدير VPS Zombie
"""

from flask import Flask, render_template_string, jsonify, request
import subprocess
import os
import psutil
import json
from datetime import datetime

app = Flask(__name__)

# قالب HTML للوحة التحكم
DASHBOARD_TEMPLATE = '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🧟 Zombie VPS Dashboard</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: white;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .header h1 {
            font-size: 3em;
            margin: 0;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: rgba(255,255,255,0.1);
            border-radius: 10px;
            padding: 20px;
            text-align: center;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
        }
        .stat-card h3 {
            margin: 0 0 10px 0;
            font-size: 1.2em;
        }
        .stat-card .value {
            font-size: 2em;
            font-weight: bold;
            color: #4CAF50;
        }
        .bots-section {
            background: rgba(255,255,255,0.1);
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
        }
        .bot-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px;
            margin: 10px 0;
            background: rgba(255,255,255,0.1);
            border-radius: 5px;
        }
        .status-running { color: #4CAF50; }
        .status-stopped { color: #f44336; }
        .btn {
            background: #4CAF50;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 5px;
            cursor: pointer;
            margin: 0 5px;
        }
        .btn:hover { background: #45a049; }
        .btn-danger { background: #f44336; }
        .btn-danger:hover { background: #da190b; }
        .btn-warning { background: #ff9800; }
        .btn-warning:hover { background: #e68900; }
        .logs-section {
            background: rgba(0,0,0,0.3);
            border-radius: 10px;
            padding: 20px;
            margin-top: 20px;
        }
        .logs {
            background: #000;
            color: #0f0;
            padding: 15px;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            height: 300px;
            overflow-y: auto;
            white-space: pre-wrap;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧟 Zombie VPS Dashboard</h1>
            <p>لوحة تحكم الخادم الافتراضي</p>
        </div>
        
        <div class="stats-grid">
            <div class="stat-card">
                <h3>🖥️ استخدام المعالج</h3>
                <div class="value">{{ cpu_usage }}%</div>
            </div>
            <div class="stat-card">
                <h3>💾 استخدام الذاكرة</h3>
                <div class="value">{{ memory_usage }}%</div>
            </div>
            <div class="stat-card">
                <h3>💽 مساحة القرص</h3>
                <div class="value">{{ disk_usage }}%</div>
            </div>
            <div class="stat-card">
                <h3>🤖 البوتات النشطة</h3>
                <div class="value">{{ active_bots }}</div>
            </div>
        </div>
        
        <div class="bots-section">
            <h2>🤖 إدارة البوتات</h2>
            <div class="bot-controls">
                <button class="btn" onclick="controlBots('start')">🚀 تشغيل الكل</button>
                <button class="btn btn-warning" onclick="controlBots('restart')">🔄 إعادة تشغيل</button>
                <button class="btn btn-danger" onclick="controlBots('stop')">🛑 إيقاف الكل</button>
            </div>
            
            <div id="bots-list">
                {% for bot in bots %}
                <div class="bot-item">
                    <span>{{ bot.name }}</span>
                    <span class="status-{{ bot.status }}">{{ bot.status_text }}</span>
                    <div>
                        <button class="btn" onclick="controlBot('{{ bot.name }}', 'start')">▶️</button>
                        <button class="btn btn-warning" onclick="controlBot('{{ bot.name }}', 'restart')">🔄</button>
                        <button class="btn btn-danger" onclick="controlBot('{{ bot.name }}', 'stop')">⏹️</button>
                    </div>
                </div>
                {% endfor %}
            </div>
        </div>
        
        <div class="logs-section">
            <h2>📋 سجلات النظام</h2>
            <div class="logs" id="logs">
                جاري تحميل السجلات...
            </div>
        </div>
    </div>
    
    <script>
        function controlBots(action) {
            fetch('/api/bots/' + action, {method: 'POST'})
                .then(response => response.json())
                .then(data => {
                    alert(data.message);
                    location.reload();
                });
        }
        
        function controlBot(botName, action) {
            fetch('/api/bot/' + botName + '/' + action, {method: 'POST'})
                .then(response => response.json())
                .then(data => {
                    alert(data.message);
                    location.reload();
                });
        }
        
        function loadLogs() {
            fetch('/api/logs')
                .then(response => response.text())
                .then(data => {
                    document.getElementById('logs').textContent = data;
                });
        }
        
        // تحديث السجلات كل 5 ثوان
        setInterval(loadLogs, 5000);
        loadLogs();
        
        // تحديث الصفحة كل 30 ثانية
        setInterval(() => location.reload(), 30000);
    </script>
</body>
</html>
'''

def get_system_stats():
    """الحصول على إحصائيات النظام"""
    return {
        'cpu_usage': round(psutil.cpu_percent(interval=1), 1),
        'memory_usage': round(psutil.virtual_memory().percent, 1),
        'disk_usage': round(psutil.disk_usage('/').percent, 1),
        'uptime': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    }

def get_bots_status():
    """الحصول على حالة البوتات"""
    try:
        result = subprocess.run(['sudo', 'supervisorctl', 'status', 'zombie-bots:*'], 
                              capture_output=True, text=True)
        bots = []
        
        for line in result.stdout.split('\n'):
            if line.strip():
                parts = line.split()
                if len(parts) >= 2:
                    name = parts[0].split(':')[-1]
                    status = parts[1]
                    bots.append({
                        'name': name,
                        'status': 'running' if status == 'RUNNING' else 'stopped',
                        'status_text': 'يعمل' if status == 'RUNNING' else 'متوقف'
                    })
        
        return bots
    except:
        return []

@app.route('/')
def dashboard():
    """لوحة التحكم الرئيسية"""
    stats = get_system_stats()
    bots = get_bots_status()
    stats['active_bots'] = len([b for b in bots if b['status'] == 'running'])
    
    return render_template_string(DASHBOARD_TEMPLATE, 
                                bots=bots, 
                                **stats)

@app.route('/api/bots/<action>', methods=['POST'])
def control_all_bots(action):
    """التحكم في جميع البوتات"""
    try:
        if action in ['start', 'stop', 'restart']:
            result = subprocess.run(['sudo', 'supervisorctl', action, 'zombie-bots:*'], 
                                  capture_output=True, text=True)
            return jsonify({
                'success': True,
                'message': f'تم {action} جميع البوتات بنجاح'
            })
        else:
            return jsonify({'success': False, 'message': 'أمر غير صحيح'})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)})

@app.route('/api/bot/<bot_name>/<action>', methods=['POST'])
def control_bot(bot_name, action):
    """التحكم في بوت محدد"""
    try:
        if action in ['start', 'stop', 'restart']:
            result = subprocess.run(['sudo', 'supervisorctl', action, f'zombie-bots:{bot_name}'], 
                                  capture_output=True, text=True)
            return jsonify({
                'success': True,
                'message': f'تم {action} البوت {bot_name} بنجاح'
            })
        else:
            return jsonify({'success': False, 'message': 'أمر غير صحيح'})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)})

@app.route('/api/logs')
def get_logs():
    """الحصول على السجلات"""
    try:
        result = subprocess.run(['tail', '-n', '50', '/var/log/zombie/freefire-bot.out.log'], 
                              capture_output=True, text=True)
        return result.stdout
    except:
        return "لا توجد سجلات متاحة"

@app.route('/api/status')
def api_status():
    """API حالة النظام"""
    stats = get_system_stats()
    bots = get_bots_status()
    
    return jsonify({
        'system': stats,
        'bots': bots,
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
EOF

# نسخ بوت فري فاير إلى VPS
echo "🎮 نسخ بوت فري فاير..."
sudo mkdir -p /home/zombie/bots/freefire
sudo cp -r /home/ubuntu/freefire_telegram_bot/* /home/zombie/bots/freefire/ 2>/dev/null || true

# تعيين الصلاحيات
sudo chown -R zombie:zombie /home/zombie
sudo chmod +x /home/zombie/apps/zombie_manager.py

# إعادة تحميل Supervisor
sudo supervisorctl reread
sudo supervisorctl update

# إنشاء ملف معلومات VPS
sudo tee /home/zombie/vps_info.txt > /dev/null <<EOF
🧟 Zombie VPS Information
========================

📊 لوحة التحكم: http://your-server-ip/
🤖 إدارة البوتات: zombie {start|stop|restart|status|logs}
📁 مجلد البوتات: /home/zombie/bots/
📁 مجلد التطبيقات: /home/zombie/apps/
📋 السجلات: /var/log/zombie/

🔐 بيانات الدخول:
المستخدم: zombie
كلمة المرور: ZombieVPS2024!

🗄️ قاعدة البيانات:
اسم القاعدة: zombie_db
المستخدم: zombie
كلمة المرور: ZombieDB2024!

🌐 خدمات النظام:
- Nginx: منفذ 80
- PostgreSQL: منفذ 5432
- Redis: منفذ 6379
- Zombie Manager: منفذ 5000
- FreeFire Bot: منفذ 5001

📝 أوامر مفيدة:
sudo systemctl status nginx
sudo systemctl status postgresql
sudo systemctl status redis-server
sudo supervisorctl status
zombie status
EOF

echo ""
echo "🎉 تم إعداد Zombie VPS بنجاح!"
echo "=================================="
echo "📊 لوحة التحكم: http://$(curl -s ifconfig.me)/"
echo "🤖 إدارة البوتات: zombie --help"
echo "📁 معلومات VPS: /home/zombie/vps_info.txt"
echo ""
echo "🔐 بيانات الدخول:"
echo "المستخدم: zombie"
echo "كلمة المرور: ZombieVPS2024!"
echo ""
echo "🚀 لبدء تشغيل البوتات:"
echo "zombie start"
echo ""
echo "✅ Zombie VPS جاهز للاستخدام!"
EOF

sudo chmod +x /home/ubuntu/zombie_vps_setup.sh
