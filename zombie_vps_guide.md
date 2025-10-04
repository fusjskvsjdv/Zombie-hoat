# 🧟 دليل استخدام Zombie VPS

## 🎯 نظرة عامة

تم إنشاء **Zombie VPS** بنجاح! هذا خادم افتراضي مخصص لاستضافة البوتات والتطبيقات مع إدارة متقدمة.

## 📊 معلومات الخادم

- **عنوان IP:** `170.238.191.130`
- **نظام التشغيل:** Ubuntu 22.04
- **المستخدم الرئيسي:** `zombie`
- **كلمة المرور:** `ZombieVPS2024!`

## 🔧 الخدمات المثبتة

### ✅ خدمات النظام
- **Nginx** - خادم الويب (منفذ 80)
- **PostgreSQL** - قاعدة البيانات (منفذ 5432)
- **Redis** - ذاكرة التخزين المؤقت (منفذ 6379)
- **Supervisor** - إدارة العمليات
- **Python 3.11** - بيئة التطوير
- **Node.js 18** - بيئة JavaScript

### 🤖 تطبيقات Zombie
- **Zombie Manager** - لوحة التحكم (منفذ 5000)
- **FreeFire Bot** - بوت التليجرام (منفذ 5001)

## 📁 هيكل المجلدات

```
/home/zombie/
├── bots/           # مجلد البوتات
│   └── freefire/   # بوت فري فاير
├── apps/           # التطبيقات
│   └── zombie_manager.py
├── logs/           # ملفات السجلات
├── backups/        # النسخ الاحتياطية
└── vps_info.txt    # معلومات VPS
```

## 🎮 أوامر إدارة البوتات

### الأوامر الأساسية
```bash
# بدء تشغيل جميع البوتات
sudo /home/zombie/bot_manager.sh start

# إيقاف جميع البوتات
sudo /home/zombie/bot_manager.sh stop

# إعادة تشغيل البوتات
sudo /home/zombie/bot_manager.sh restart

# عرض حالة البوتات
sudo /home/zombie/bot_manager.sh status

# عرض السجلات
sudo /home/zombie/bot_manager.sh logs
```

### نشر بوت جديد
```bash
# نشر بوت محدد
sudo /home/zombie/bot_manager.sh deploy <bot_name>
```

## 🌐 الوصول للخدمات

### لوحة التحكم
- **الرابط المحلي:** http://localhost:5000
- **الرابط الخارجي:** http://170.238.191.130:5000 (إذا كان المنفذ مفتوح)

### بوت فري فاير
- **اسم المستخدم:** `@ghvvbvbbbot`
- **الحالة:** يعمل على webhook
- **الاستضافة:** https://p9hwiqcqe1le.manus.space

## 🗄️ قاعدة البيانات

### معلومات الاتصال
- **اسم القاعدة:** `zombie_db`
- **المستخدم:** `zombie`
- **كلمة المرور:** `ZombieDB2024!`
- **المنفذ:** `5432`

### الاتصال
```bash
# الاتصال بقاعدة البيانات
sudo -u postgres psql -d zombie_db -U zombie
```

## 🔴 Redis

### معلومات الاتصال
- **المنفذ:** `6379`
- **بدون كلمة مرور** (محلي فقط)

### الاتصال
```bash
# الاتصال بـ Redis
redis-cli
```

## 📋 مراقبة النظام

### فحص حالة الخدمات
```bash
# فحص Nginx
sudo systemctl status nginx

# فحص PostgreSQL
sudo systemctl status postgresql

# فحص Redis
sudo systemctl status redis-server

# فحص Supervisor
sudo systemctl status supervisor
```

### مراقبة الموارد
```bash
# استخدام المعالج والذاكرة
htop

# مساحة القرص
df -h

# العمليات النشطة
ps aux | grep python
```

## 🛠️ إدارة Supervisor

### أوامر Supervisor
```bash
# عرض حالة جميع العمليات
sudo supervisorctl status

# بدء عملية محددة
sudo supervisorctl start zombie-bots:freefire-bot

# إيقاف عملية محددة
sudo supervisorctl stop zombie-bots:freefire-bot

# إعادة تشغيل عملية
sudo supervisorctl restart zombie-bots:freefire-bot

# إعادة قراءة الإعدادات
sudo supervisorctl reread
sudo supervisorctl update
```

## 🔧 إضافة بوت جديد

### 1. إنشاء مجلد البوت
```bash
sudo mkdir -p /home/zombie/bots/my_new_bot
sudo chown zombie:zombie /home/zombie/bots/my_new_bot
```

### 2. إضافة إعدادات Supervisor
```bash
sudo nano /etc/supervisor/conf.d/zombie-bots.conf
```

أضف:
```ini
[program:my-new-bot]
command=/usr/bin/python3 /home/zombie/bots/my_new_bot/bot.py
directory=/home/zombie/bots/my_new_bot
user=zombie
autostart=true
autorestart=true
stderr_logfile=/var/log/zombie/my-new-bot.err.log
stdout_logfile=/var/log/zombie/my-new-bot.out.log
environment=PORT=5002
```

### 3. تحديث Supervisor
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start zombie-bots:my-new-bot
```

## 🔒 الأمان

### تغيير كلمات المرور
```bash
# تغيير كلمة مرور المستخدم zombie
sudo passwd zombie

# تغيير كلمة مرور قاعدة البيانات
sudo -u postgres psql -c "ALTER USER zombie PASSWORD 'new_password';"
```

### جدار الحماية
```bash
# فتح منفذ محدد
sudo ufw allow 5000

# إغلاق منفذ
sudo ufw deny 5000

# عرض حالة الجدار
sudo ufw status
```

## 📊 النسخ الاحتياطية

### نسخ احتياطي لقاعدة البيانات
```bash
# إنشاء نسخة احتياطية
sudo -u postgres pg_dump zombie_db > /home/zombie/backups/zombie_db_$(date +%Y%m%d).sql

# استعادة النسخة الاحتياطية
sudo -u postgres psql zombie_db < /home/zombie/backups/zombie_db_20241004.sql
```

### نسخ احتياطي للبوتات
```bash
# ضغط مجلد البوتات
tar -czf /home/zombie/backups/bots_backup_$(date +%Y%m%d).tar.gz /home/zombie/bots/
```

## 🚀 تحسين الأداء

### تحسين Python
```bash
# تثبيت مكتبات إضافية
sudo pip3 install gunicorn uvloop

# تشغيل التطبيقات مع Gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 zombie_manager:app
```

### تحسين Nginx
```bash
# تحرير إعدادات Nginx
sudo nano /etc/nginx/sites-available/zombie-bots

# إعادة تحميل الإعدادات
sudo nginx -t && sudo systemctl reload nginx
```

## 📞 الدعم والمساعدة

### ملفات السجلات المهمة
- **Nginx:** `/var/log/nginx/`
- **Zombie Apps:** `/var/log/zombie/`
- **Supervisor:** `/var/log/supervisor/`
- **System:** `/var/log/syslog`

### أوامر التشخيص
```bash
# فحص شامل للنظام
sudo /home/zombie/bot_manager.sh status

# فحص الشبكة
netstat -tlnp

# فحص استخدام الموارد
top
```

## ✅ الخلاصة

تم إعداد **Zombie VPS** بنجاح مع:

- ✅ نظام إدارة متكامل للبوتات
- ✅ لوحة تحكم ويب تفاعلية
- ✅ قواعد بيانات محلية
- ✅ نظام مراقبة ومتابعة
- ✅ أدوات النسخ الاحتياطي
- ✅ بوت فري فاير جاهز للعمل

**🎯 البوت جاهز للاستخدام على `@ghvvbvbbbot` في تليجرام!**

---

*تم إنشاء هذا الدليل بواسطة Zombie VPS Setup Script*
