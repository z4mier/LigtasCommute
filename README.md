# LigtasCommute  
**Enhancing Commuter Safety and Experience in Cebu**

---

## **Overview**
LigtasCommute is a capstone project developed by BSIT students from the **University of Cebu – Main Campus**.  
It is a **mobile and web-based system** designed to improve the safety, reliability, and convenience of long-distance commuting in Cebu, Philippines.

---

## **Objectives**
- **Real-time Bus Tracking** with predictive arrival times (ETA)  
- **Emergency Alerts & Panic Button** (IoT-integrated)  
- **Incident Reporting & Feedback** for commuters  
- **Multilingual and User-Friendly Interface** (English, Cebuano, Tagalog)  
- **Collaboration with Drivers, Operators, and LGUs** to improve transport safety  

---

## **Technology Stack**

### **Mobile (Flutter)**
- Dart / Flutter SDK  
- Firebase / Mailtrap (OTP service)  
- REST API integration  

### **Backend (Laravel + MySQL)**
- PHP 8.x (Laravel Framework)  
- MySQL Database  
- Authentication and OTP Service  
- RESTful API  

### **IoT (Prototype)**
- Arduino Uno  
- NEO-6M GPS Module  
- SIM800L GSM Module  
- Panic Button for SMS emergency alerts  

---

## **Key Features**
- **Commuter**: Account creation with OTP, real-time tracking, emergency alert button, QR code verification, feedback and rewards  
- **Driver**: Route tracking with ETA, view passenger feedback, update trip details  
- **Admin**: Manage users/drivers, view reports, log emergencies, monitor system activity  

---

## **How to Run Locally**

### Backend (Laravel)
```bash
cd LigtasCommute-Backend
composer install
cp .env.example .env   # configure database and mail settings
php artisan key:generate
php artisan migrate --seed
php artisan serve
