EcoTrack: Neighborhood Waste & Recycling Coordinator
A full-stack mobile application built with Flutter and Node.js for the SE3050 - User Experience Engineering module.
🎯 Project Overview
EcoTrack is a comprehensive mobile platform designed to streamline waste management and recycling processes within a community. The system connects key stakeholders—residents, businesses, waste collection drivers, and recycling center managers—through a centralized, user-friendly application to foster efficiency, communication, and community engagement.
🔥 The Problem
Current waste management systems often suffer from inefficient scheduling, poor communication between residents and service providers, manual and error-prone record-keeping at recycling facilities, and a lack of tools for community-driven environmental initiatives. EcoTrack aims to solve these problems with a unified digital solution.
✨ Key Features
The application is built around four core components, each managed by a team member:
♻️ Waste Reporting & Requests: Allows users to report illegal dumping, request special waste collections, and track the status of their requests from submission to completion.
🚚 Collection & Scheduling: A logistics dashboard for managers to view incoming requests, schedule pickups, assign routes to drivers, and monitor the status of collection tasks in real-time.
🏢 Recycling Center Management: A dashboard for recycling center staff to digitally record incoming waste, categorize materials, manage inventory of recyclables, and generate automated reports.
👨‍👩‍👧‍👦 Community Engagement: A social hub for residents to organize neighborhood cleanup events, share environmental tips, and report local issues, with gamification elements to encourage participation.
💻 Technology Stack
This project is a monorepo containing a separate frontend and backend.
Area	Technology
Frontend	Flutter, Dart
Backend	Node.js, Express.js
Database	MongoDB Atlas (Mongoose)
📁 Project Structure
The repository is structured as a monorepo to contain both the frontend and backend code.
code
Code
/
|-- backend_nodejs/       # Contains the Node.js, Express, and Mongoose backend server
|-- frontend_flutter/     # Contains the Flutter mobile application
|-- .gitignore
`-- README.md
To work on the mobile app, open the frontend_flutter folder in your IDE.
To work on the server, open the backend_nodejs folder in your IDE.
🚀 Getting Started
Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.
Prerequisites
You must have the following software installed on your machine:
Node.js (LTS version recommended)
Flutter SDK
Android Studio (for the Android SDK and Emulator)
Visual Studio Code (recommended code editor)
Installation & Setup
1. Clone the Repository
code
Bash
git clone <your-github-repository-url>
cd <repository-name>
2. Set Up the Backend
First, we need to configure and install the dependencies for the server.
code
Bash
# Navigate to the backend directory
cd backend_nodejs

# Create the .env file
# Create a new file named .env in this directory.
# Copy the contents of .env.example (or get them from a teammate) and paste them into .env.
# Fill in your own MONGO_URI and other secret values.
.env file example:
code
Code
PORT=5000
MONGO_URI="your_mongodb_connection_string"
JWT_SECRET=YOUR_LONG_RANDOM_SECRET
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_google_app_password
code
Bash
# Install all required npm packages
npm install
3. Set Up the Frontend
Now, let's set up the Flutter mobile app.
code
Bash
# Navigate to the frontend directory
cd ../frontend_flutter

# Download all required Flutter packages
flutter pub get
▶️ Running the Application
To run the full application, you must have both the backend server and the frontend app running at the same time.
Step 1: Start the Backend Server
Open a terminal and navigate to the backend_nodejs directory.
Run the development server command:
code
Bash
npm run dev
You should see output confirming the server is running, for example:
MongoDB connected successfully
Server running on port 5000
Step 2: Start the Frontend Application
Leave the backend terminal running.
Open a new, separate terminal and navigate to the frontend_flutter directory.
Make sure you have an Android Emulator running (you can start one from Android Studio's Device Manager).
Run the application:
code
Bash
flutter run
The Flutter app will now build and launch on your running emulator. It is already configured to connect to the local backend server.
Note: The Flutter app connects to the backend using the special IP address http://10.0.2.2:5000. This address is automatically mapped by the Android Emulator to your computer's localhost.
👥 Team Members
Name	IT Number
E.A.D.T.M. EDIRISINGHE	IT23811522
M N.W.D.E RANDUNU	IT23846104
MANMITH A.G.L	IT23816640
ANJANA I.M.A.A.	IT23815346
