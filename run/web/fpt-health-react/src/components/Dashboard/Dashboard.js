"use client";

import { useEffect, useState } from "react";
import "./Dashboard.css";
import bannerImg from "../img/pexels-pixabay-40568.jpg";
import axios from "axios";
import "./AppointmentDetailsModal.css";

function Dashboard() {
  const [patientData, setPatientData] = useState(null);
  const [imageValid, setImageValid] = useState(false);
  const [imagePath, setImagePath] = useState("");
  const [appointmentVisible, setAppointmentVisible] = useState(true);
  const patientId = sessionStorage.getItem("patient_id");
  const [currentAppointmentPage, setCurrentAppointmentPage] = useState(1);
  const [currentRecordPage, setCurrentRecordPage] = useState(1);
  const itemsPerPage = 3;
  const [openEditAppointment, setOpenEditAppointment] = useState(false);
  const [openEditPatient, setOpenEditPatient] = useState(false);
  const [editAppointmentData, setEditAppointmentData] = useState(null);
  const [bookedSlots, setBookedSlots] = useState([]);
  const [availableSlots, setAvailableSlots] = useState([]);
  const [selectedRecord, setSelectedRecord] = useState(null);
  const [selectedAppointment, setSelectedAppointment] = useState(null);
  const [editFormData, setEditFormData] = useState({});
  const [imageUploading, setImageUploading] = useState(false);
  const [appointmentDetails, setAppointmentDetails] = useState(null);
  const [showAppointmentDetails, setShowAppointmentDetails] = useState(false);

  // Simple solution: Convert to smaller base64 and resize image
  const resizeAndConvertImage = async (file) => {
    return new Promise((resolve) => {
      const canvas = document.createElement("canvas");
      const ctx = canvas.getContext("2d");
      const img = new Image();

      img.onload = () => {
        // Resize image to max 300x300 to reduce size
        const maxSize = 300;
        let { width, height } = img;

        if (width > height) {
          if (width > maxSize) {
            height = (height * maxSize) / width;
            width = maxSize;
          }
        } else {
          if (height > maxSize) {
            width = (width * maxSize) / height;
            height = maxSize;
          }
        }

        canvas.width = width;
        canvas.height = height;

        ctx.drawImage(img, 0, 0, width, height);

        // Convert to base64 with lower quality to reduce size
        const base64 = canvas.toDataURL("image/jpeg", 0.7); // 70% quality
        resolve(base64);
      };

      img.src = URL.createObjectURL(file);
    });
  };

  const handleImageChange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      showNotification("Image size must be less than 5MB", "error");
      return;
    }

    // Validate file type
    if (!file.type.startsWith("image/")) {
      showNotification("Please select a valid image file", "error");
      return;
    }

    setImageUploading(true);

    try {
      // Resize and use base64
      const imageUrl = await resizeAndConvertImage(file);

      // Update patient image using the /update-image API
      const response = await axios.put("http://localhost:8081/api/v1/patients/update-image", {
        patient_id: Number.parseInt(patientId),
        patient_img: imageUrl,
      });

      if (response.data.message === "Image updated successfully") {
        setImagePath(imageUrl);
        setPatientData((prev) => ({ ...prev, patient_img: imageUrl }));
        setImageValid(true);
        showNotification("Image updated successfully!", "success");
      }
    } catch (error) {
      console.error("Error uploading image:", error);
      showNotification("Failed to update image. Please try again.", "error");
    } finally {
      setImageUploading(false);
    }
  };

  const toggleAppointmentVisible = () => {
    setAppointmentVisible(!appointmentVisible);
    setCurrentRecordPage(1);
    setCurrentAppointmentPage(1);
  };

  const timeSlots = [
    { label: "08:00 AM - 09:00 AM", value: 1, start: "08:00", end: "09:00" },
    { label: "09:00 AM - 10:00 AM", value: 2, start: "09:00", end: "10:00" },
    { label: "10:00 AM - 11:00 AM", value: 3, start: "10:00", end: "11:00" },
    { label: "11:00 AM - 12:00 PM", value: 4, start: "11:00", end: "12:00" },
    { label: "01:00 PM - 02:00 PM", value: 5, start: "13:00", end: "14:00" },
    { label: "02:00 PM - 03:00 PM", value: 6, start: "14:00", end: "15:00" },
    { label: "03:00 PM - 04:00 PM", value: 7, start: "15:00", end: "16:00" },
    { label: "04:00 PM - 05:00 PM", value: 8, start: "16:00", end: "17:00" },
  ];

  const formatTimeSlot = (slot) => {
    switch (slot) {
      case 1:
        return "8:00 AM - 9:00 AM";
      case 2:
        return "9:00 AM - 10:00 AM";
      case 3:
        return "10:00 AM - 11:00 AM";
      case 4:
        return "11:00 AM - 12:00 PM";
      case 5:
        return "01:00 PM - 02:00 PM";
      case 6:
        return "02:00 PM - 03:00 PM";
      case 7:
        return "03:00 PM - 04:00 PM";
      case 8:
        return "04:00 PM - 05:00 PM";
      default:
        return "Slot Time Not Defined";
    }
  };

  const [formData, setFormData] = useState({
    date: "",
    timeSlot: "",
  });

  const handleCancelEditAppointment = () => {
    setFormData({
      date: "",
      timeSlot: "",
    });
    setBookedSlots([]);
    setAvailableSlots([]);
    setEditAppointmentData(null);
    setOpenEditAppointment(false);
  };

  useEffect(() => {
    if (formData.date && editAppointmentData) {
      axios
        .get(`http://localhost:8081/api/v1/appointments/${editAppointmentData.doctor_id}/slots`)
        .then((response) => {
          setBookedSlots(response.data);
        })
        .catch((error) => {
          console.error("Error fetching booked slots!", error);
        });
    }
  }, [formData.date, editAppointmentData]);

  useEffect(() => {
    if (formData.date && bookedSlots.length > 0) {
      const bookedSlotsForDate = bookedSlots
        .filter((slot) => {
          const slotDate = new Date(slot.medical_day).toISOString().split("T")[0];
          return slotDate === formData.date;
        })
        .map((slot) => slot.slot);
      const available = timeSlots.filter((slot) => !bookedSlotsForDate.includes(slot.value));
      setAvailableSlots(available);
    } else {
      setAvailableSlots(timeSlots);
    }
  }, [formData.date, bookedSlots]);

  const handleDateChange = (date) => {
    setFormData({
      ...formData,
      date: date,
      timeSlot: "",
    });
  };

  const handleViewDetails = (record) => {
    setSelectedRecord(record);
  };

  const handleViewAppointmentDetails = async (appointment) => {
    try {
      const response = await axios.get(`http://localhost:8081/api/v1/appointments/${appointment.appointment_id}`);
      setAppointmentDetails(response.data);
      setShowAppointmentDetails(true);
    } catch (error) {
      console.error("Error fetching appointment details:", error);
      showNotification("Failed to load appointment details", "error");
    }
  };

  const handleTimeSlotChange = (slot) => {
    setFormData({
      ...formData,
      timeSlot: slot,
    });
  };

  const renderDateButtons = () => {
    const dates = generateDateButtons();
    return (
      <div className="date-container">
        <label>Date</label>
        <div className="date-select">
          <div className="date-buttons">
            {dates.map((date) => (
              <button key={date.value} className={formData.date === date.value ? "selected" : ""} onClick={() => handleDateChange(date.value)}>
                {date.label}
              </button>
            ))}
          </div>
          <span>OR</span>
          <input type="date" value={formData.date} onChange={(e) => handleDateChange(e.target.value)} min={new Date().toISOString().split("T")[0]} className="ipSelectDate" />
        </div>
      </div>
    );
  };

  const renderTimeSlots = () => {
    return (
      <div className="time-container">
        <label>Time</label>
        <div className="time-slots">
          {availableSlots.map((slot) => (
            <button
              key={slot.value}
              className={formData.timeSlot === slot.value ? "selected" : ""}
              onClick={() => handleTimeSlotChange(slot.value)}
              disabled={isTimeSlotPast(formData.date, slot.start)}
              style={{
                backgroundColor: isTimeSlotPast(formData.date, slot.start) ? "#d3d3d3" : "",
                pointerEvents: isTimeSlotPast(formData.date, slot.start) ? "none" : "auto",
              }}
            >
              {slot.label}
            </button>
          ))}
        </div>
      </div>
    );
  };

  useEffect(() => {
    if (openEditAppointment) {
      document.body.classList.add("no-scroll");
    } else {
      document.body.classList.remove("no-scroll");
    }
  }, [openEditAppointment]);

  const isTimeSlotPast = (date, startTime) => {
    const appointmentDate = new Date(date);
    const currentDate = new Date();
    const [startHour, startMinute] = startTime.split(":").map(Number);

    appointmentDate.setHours(startHour, startMinute, 0, 0);

    return appointmentDate < currentDate;
  };

  const generateDateButtons = () => {
    const today = new Date();
    const dates = [];
    for (let i = 0; i < 3; i++) {
      const date = new Date(today);
      date.setDate(today.getDate() + i);
      const dateString = date.toISOString().split("T")[0];
      dates.push({
        label: i === 0 ? `Today (${dateString})` : i === 1 ? `Tomorrow (${dateString})` : `Day after tomorrow (${dateString})`,
        value: dateString,
      });
    }
    return dates;
  };

  const handleConfirmEditAppointment = () => {
    if (editAppointmentData) {
      handleEditAppointment(editAppointmentData);
    }
    setOpenEditAppointment(false);
  };

  const handleEditAppointment = async (appointment) => {
    try {
      await axios.put(`http://localhost:8081/api/v1/appointments/update`, {
        appointment_id: appointment.appointment_id,
        medical_day: formData.date,
        slot: formData.timeSlot,
        status: "Pending",
      });
      sessionStorage.setItem("appointmentMessage", "Appointment updated successfully!");
      window.location.reload();
    } catch (error) {
      console.error("Failed to update the appointment.", error);
    }
  };

  // Filter appointments to show only from today onwards
  const filterFutureAppointments = (appointments) => {
    const today = new Date();
    today.setHours(0, 0, 0, 0); // Set to start of today

    return appointments.filter((appointment) => {
      const appointmentDate = new Date(appointment.medical_day);
      appointmentDate.setHours(0, 0, 0, 0);
      return appointmentDate >= today;
    });
  };

  // Get initials for avatar
  const getInitials = (name) => {
    if (!name) return "?";
    return name
      .split(" ")
      .map((word) => word.charAt(0))
      .join("")
      .toUpperCase()
      .slice(0, 2);
  };

  useEffect(() => {
    const fetchPatientData = async () => {
      try {
        if (patientId) {
          const response = await axios.get(`http://localhost:8081/api/v1/patients/search?patient_id=${patientId}`);
          const patientData = response.data[0];
          console.log("Patient Data:", patientData);
          setPatientData(patientData);

          // Initialize edit form data
          setEditFormData({
            patient_name: patientData.patient_name || "",
            patient_dob: patientData.patient_dob ? formatDateToInput(patientData.patient_dob) : "",
            patient_gender: patientData.patient_gender || "Male",
            patient_email: patientData.patient_email || "",
            patient_phone: patientData.patient_phone || "",
            patient_address: patientData.patient_address || "",
          });

          if (patientData.patient_img) {
            // Check if it's already a URL or a local path
            if (patientData.patient_img.startsWith("http") || patientData.patient_img.startsWith("data:")) {
              setImagePath(patientData.patient_img);
            } else {
              setImagePath(`http://localhost:8080/${patientData.patient_img}`);
            }
            setImageValid(true);
          } else {
            setImageValid(false);
          }
        } else {
          console.error("Invalid patientId:", patientId);
        }
      } catch (error) {
        console.error("Error fetching patient data:", error);
      }
    };

    fetchPatientData();
  }, [patientId]);

  const appointments = patientData ? patientData.appointmentsList : [];
  const medicalRecords = patientData ? patientData.medicalrecordsList : [];

  // Filter appointments to show only future appointments
  const futureAppointments = filterFutureAppointments(appointments);
  const sortedAppointments = futureAppointments && futureAppointments.slice().sort((a, b) => new Date(a.medical_day) - new Date(b.medical_day));
  const sortedMedicalRecords = medicalRecords && medicalRecords.slice().sort((a, b) => new Date(b.follow_up_date) - new Date(a.follow_up_date));

  const totalAppointmentPages = Math.ceil(sortedAppointments.length / itemsPerPage);
  const startAppointmentIndex = (currentAppointmentPage - 1) * itemsPerPage;
  const currentAppointments = sortedAppointments.slice(startAppointmentIndex, startAppointmentIndex + itemsPerPage);

  const totalRecordPages = Math.ceil(medicalRecords.length / itemsPerPage);
  const startRecordIndex = (currentRecordPage - 1) * itemsPerPage;
  const currentRecords = sortedMedicalRecords.slice(startRecordIndex, startRecordIndex + itemsPerPage);

  const getStatusIcon = (status) => {
    switch (status) {
      case "PENDING":
        return <span className="status-icon pending"></span>;
      case "COMPLETED":
        return <span className="status-icon completed"></span>;
      case "CANCELLED":
        return <span className="status-icon cancelled"></span>;
      default:
        return <span className="status-icon"></span>;
    }
  };

  const [doctors, setDoctors] = useState([]);
  const [departments, setDepartments] = useState([]);

  useEffect(() => {
    const fetchDetails = async () => {
      try {
        const [patientResponse, doctorsResponse, departmentsResponse] = await Promise.all([axios.get("http://localhost:8081/api/v1/patients/list"), axios.get("http://localhost:8081/api/v1/doctors/list"), axios.get("http://localhost:8081/api/v1/departments/list")]);

        setDoctors(doctorsResponse.data);
        setDepartments(departmentsResponse.data);
      } catch (error) {
        console.error("Error fetching details", error);
      }
    };

    fetchDetails();
  }, []);

  const getDepartmentName = (doctorId) => {
    const doctor = doctors.find((doc) => doc.doctor_id === doctorId);
    if (doctor) {
      const department = departments.find((dep) => dep.department_id === doctor.department_id);
      return department ? department.department_name : "Unknown Department";
    }
    return "Unknown Department";
  };

  const handleOpenEditAppointment = (appointment) => {
    setEditAppointmentData(appointment);
    setOpenEditAppointment(true);
  };

  const isEditCancelDisabled = (appointmentDate, appointmentSlot) => {
    const startTime = appointmentSlot.split(" - ")[0];
    const appointmentDateTime = new Date(`${appointmentDate}T${convertTo24Hour(startTime)}`);
    const currentTime = new Date();
    const timeDifference = appointmentDateTime - currentTime;
    const twoHoursInMillis = 2 * 60 * 60 * 1000;
    return timeDifference < twoHoursInMillis;
  };

  const convertTo24Hour = (time) => {
    const [timePart, modifier] = time.split(" ");
    let [hours, minutes] = timePart.split(":");
    if (modifier === "PM" && hours !== "12") {
      hours = Number.parseInt(hours, 10) + 12;
    }
    if (modifier === "AM" && hours === "12") {
      hours = "00";
    }
    hours = hours < 10 ? `0${hours}` : hours;

    return `${hours}:${minutes}:00`;
  };

  const handleEditFormChange = (e) => {
    const { name, value } = e.target;

    // Phone number validation - only allow 10 digits
    if (name === "patient_phone") {
      const phoneRegex = /^\d{0,10}$/;
      if (!phoneRegex.test(value)) {
        return; // Don't update if not valid
      }
    }

    // Special handling for date field - format as user types
    if (name === "patient_dob") {
      // Remove all non-digits
      const digitsOnly = value.replace(/\D/g, "");

      // Format as dd/mm/yyyy
      let formattedValue = "";
      if (digitsOnly.length >= 1) {
        formattedValue = digitsOnly.substring(0, 2);
      }
      if (digitsOnly.length >= 3) {
        formattedValue += "/" + digitsOnly.substring(2, 4);
      }
      if (digitsOnly.length >= 5) {
        formattedValue += "/" + digitsOnly.substring(4, 8);
      }

      setEditFormData((prev) => ({
        ...prev,
        [name]: formattedValue,
      }));
      return;
    }

    setEditFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  // Parse date from input format (dd/mm/yyyy) to backend format (yyyy-MM-dd)
  const parseDateFromInput = (str) => {
    if (!str) return "";

    try {
      const parts = str.split("/");
      if (parts.length !== 3) return "";

      const day = parts[0].padStart(2, "0");
      const month = parts[1].padStart(2, "0");
      const year = parts[2];

      // Validate ranges
      const dayNum = Number.parseInt(day, 10);
      const monthNum = Number.parseInt(month, 10);
      const yearNum = Number.parseInt(year, 10);

      if (dayNum < 1 || dayNum > 31 || monthNum < 1 || monthNum > 12 || yearNum < 1900 || yearNum > 2100) {
        return "";
      }

      // Return in yyyy-MM-dd format for backend
      return `${year}-${month}-${day}`;
    } catch (error) {
      console.error("Error parsing date:", error);
      return "";
    }
  };

  const isValidDateFormat = (dateStr) => {
    if (!dateStr) return false;

    const regex = /^\d{2}\/\d{2}\/\d{4}$/;
    if (!regex.test(dateStr)) return false;

    try {
      const [day, month, year] = dateStr.split("/").map(Number);

      // Basic range validation
      if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900 || year > 2100) {
        return false;
      }

      // Create date and validate it's a real date
      const date = new Date(year, month - 1, day);
      return date.getFullYear() === year && date.getMonth() === month - 1 && date.getDate() === day;
    } catch (error) {
      return false;
    }
  };

  // Hàm hiển thị thông báo tùy chỉnh
  const showNotification = (message, type = "success") => {
    const notification = document.createElement("div");
    notification.className = `notification ${type}`;
    notification.innerHTML = `
    <div style="
      position: fixed;
      top: 20px;
      right: 20px;
      padding: 15px 25px;
      border-radius: 8px;
      background-color: ${type === "success" ? "#4caf50" : "#f44336"};
      color: white;
      box-shadow: 0 2px 8px rgba(0,0,0,0.2);
      z-index: 1000;
      animation: slideIn 0.3s ease-out, fadeOut 0.3s ease-in 2.7s;
    ">
      ${message}
    </div>
    <style>
      @keyframes slideIn {
        from { transform: translateX(100%); }
        to { transform: translateX(0); }
      }
      @keyframes fadeOut {
        from { opacity: 1; }
        to { opacity: 0; }
      }
      .notification {
        display: flex;
        align-items: center;
      }
    </style>
  `;
    document.body.appendChild(notification);
    setTimeout(() => {
      notification.remove();
    }, 3000);
  };

  // Hàm hiển thị modal xác nhận
  const showConfirmModal = (message, onConfirm, onCancel) => {
    const modal = document.createElement("div");
    modal.className = "confirm-modal";
    modal.innerHTML = `
    <div style="
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0,0,0,0.5);
      display: flex;
      justify-content: center;
      align-items: center;
      z-index: 1000;
    ">
      <div style="
        background: white;
        padding: 20px;
        border-radius: 8px;
        max-width: 400px;
        width: 100%;
        text-align: center;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      ">
        <h3 style="margin: 0 0 15px; font-size: 18px;">Confirm Action</h3>
        <p style="margin: 0 0 20px;">${message}</p>
        <div style="display: flex; justify-content: center; gap: 10px;">
          <button style="
            padding: 10px 20px;
            background: #004b91;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
          " class="confirm-btn">Yes</button>
          <button style="
            padding: 10px 20px;
            background: #f44336;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
          " class="cancel-btn">No</button>
        </div>
      </div>
    </div>
  `;
    document.body.appendChild(modal);

    const confirmBtn = modal.querySelector(".confirm-btn");
    const cancelBtn = modal.querySelector(".cancel-btn");

    confirmBtn.addEventListener("click", () => {
      onConfirm();
      modal.remove();
    });
    cancelBtn.addEventListener("click", () => {
      onCancel();
      modal.remove();
    });
  };

  const handleSavePatient = async () => {
    console.log("Current editFormData:", editFormData); // Debug log

    // Validate phone number
    if (editFormData.patient_phone.length !== 10) {
      showNotification("Phone number must be exactly 10 digits", "error");
      return;
    }

    // Debug date validation
    console.log("Date to validate:", editFormData.patient_dob);
    console.log("Is valid date format:", isValidDateFormat(editFormData.patient_dob));

    // Validate date format
    if (!isValidDateFormat(editFormData.patient_dob)) {
      showNotification("Please enter date in dd/mm/yyyy format", "error");
      return;
    }

    showConfirmModal(
      "Are you sure you want to save the changes to your profile?",
      async () => {
        try {
          // Convert date from dd/mm/yyyy to yyyy-MM-dd format (backend expects this)
          const backendDateFormat = parseDateFromInput(editFormData.patient_dob);
          console.log("Original date:", editFormData.patient_dob); // Debug log
          console.log("Backend date format:", backendDateFormat); // Debug log

          // Check if date conversion failed
          if (!backendDateFormat) {
            showNotification("Invalid date format. Please use dd/mm/yyyy format.", "error");
            return;
          }

          const updateData = {
            patient_id: Number.parseInt(patientId),
            patient_name: editFormData.patient_name,
            patient_dob: backendDateFormat, // Send in yyyy-MM-dd format
            patient_gender: editFormData.patient_gender,
            patient_phone: editFormData.patient_phone,
            patient_address: editFormData.patient_address,
            patient_email: patientData.patient_email, // Keep original email
            patient_password: patientData.patient_password, // Keep original password
            patient_username: patientData.patient_username, // Keep original username
            patient_code: patientData.patient_code, // Keep original code
            patient_img: patientData.patient_img, // Keep original image
          };

          console.log("Update data being sent:", updateData); // Debug log

          const response = await axios.put("http://localhost:8081/api/v1/patients/update2", updateData);

          console.log("Update response:", response.data); // Debug log

          // Update local state with the new date in the correct format for display
          setPatientData((prev) => ({
            ...prev,
            patient_name: editFormData.patient_name,
            patient_dob: backendDateFormat, // Store in backend format
            patient_gender: editFormData.patient_gender,
            patient_phone: editFormData.patient_phone,
            patient_address: editFormData.patient_address,
          }));

          setOpenEditPatient(false);
          showNotification("Patient information updated successfully!", "success");
        } catch (error) {
          console.error("Error updating patient data:", error);
          console.error("Error response:", error.response?.data); // Debug log
          showNotification("Failed to update patient information. Please try again.", "error");
        }
      },
      () => {
        // Do nothing on cancel
      }
    );
  };

  // Format date from backend (có thể là yyyy-MM-ddTHH:mm:ss hoặc yyyy-MM-dd) to display format (dd/mm/yyyy)
  const formatDateToInput = (dateStr) => {
    if (!dateStr) return "";

    // Xử lý LocalDateTime format (yyyy-MM-ddTHH:mm:ss)
    let datePart = dateStr;
    if (dateStr.includes("T")) {
      datePart = dateStr.split("T")[0]; // Lấy phần ngày, bỏ phần thời gian
    }

    const [year, month, day] = datePart.split("-");
    return `${day}/${month}/${year}`;
  };

  const handleCancelEdit = () => {
    // Reset form data to original values
    setEditFormData({
      patient_name: patientData.patient_name || "",
      patient_dob: patientData.patient_dob ? formatDateToInput(patientData.patient_dob) : "",
      patient_gender: patientData.patient_gender || "Male",
      patient_email: patientData.patient_email || "",
      patient_phone: patientData.patient_phone || "",
      patient_address: patientData.patient_address || "",
    });
    setOpenEditPatient(false);
  };

  return (
    <main className="dashboard-container">
      {/* Profile-style Appointment Details Modal */}
      {showAppointmentDetails && (
        <div className="appointment-details-overlay">
          <div className="appointment-details-modal">
            {/* Profile Header */}
            <div className="profile-header">
              <div className="profile-main">
                <div className="profile-avatar">{appointmentDetails?.patient && appointmentDetails.patient.length > 0 ? getInitials(appointmentDetails.patient[0].patient_name) : "AP"}</div>
                <div className="profile-info">
                  <h1>Medical Appointment</h1>
                  <p className="profile-subtitle">{appointmentDetails?.patient && appointmentDetails.patient.length > 0 ? appointmentDetails.patient[0].patient_name : "Patient Information"}</p>
                  <div className="profile-meta">
                    <div className="meta-item">
                      <svg className="meta-icon" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M9 11H7v2h2v-2zm4 0h-2v2h2v-2zm4 0h-2v2h2v-2zm2-7h-1V2h-2v2H8V2H6v2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H5V9h14v11z" />
                      </svg>
                      <span>
                        {appointmentDetails
                          ? new Date(appointmentDetails.medical_day).toLocaleDateString("en-US", {
                              month: "short",
                              day: "numeric",
                              year: "numeric",
                            })
                          : ""}
                      </span>
                    </div>
                    <div className="meta-item">
                      <svg className="meta-icon" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z" />
                        <path d="M12.5 7H11v6l5.25 3.15.75-1.23-4.5-2.67z" />
                      </svg>
                      <span>{appointmentDetails ? formatTimeSlot(appointmentDetails.slot) : ""}</span>
                    </div>
                    <div className="meta-item">
                      <svg className="meta-icon" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                      </svg>
                      <span>ID: #{appointmentDetails?.appointment_id}</span>
                    </div>
                  </div>
                </div>
              </div>
              <div className="profile-status">
                <div className={`status-badge ${appointmentDetails?.status?.toLowerCase()}`}>
                  <div className="status-indicator"></div>
                  <span>{appointmentDetails?.status || "Unknown"}</span>
                </div>
                <button className="close-btn" onClick={() => setShowAppointmentDetails(false)}>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z" />
                  </svg>
                </button>
              </div>
            </div>

            {/* Profile Content */}
            <div className="profile-content">
              {appointmentDetails ? (
                <>
                  {/* Appointment Details Section */}
                  <div className="profile-section appointment-section">
                    <div className="section-title">
                      <div className="section-icon">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                          <path d="M19 3h-1V1h-2v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V8h14v11zM7 10h5v5H7z" />
                        </svg>
                      </div>
                      <h2>Appointment Details</h2>
                    </div>
                    <div className="appointment-details-grid">
                      <div className="detail-card">
                        <div className="detail-card-header">
                          <div className="detail-card-icon">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                              <path d="M9 11H7v2h2v-2zm4 0h-2v2h2v-2zm4 0h-2v2h2v-2zm2-7h-1V2h-2v2H8V2H6v2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H5V9h14v11z" />
                            </svg>
                          </div>
                          <div className="detail-card-title">Appointment Date</div>
                        </div>
                        <div className="detail-card-value">
                          {new Date(appointmentDetails.medical_day).toLocaleDateString("en-US", {
                            weekday: "long",
                            year: "numeric",
                            month: "long",
                            day: "numeric",
                          })}
                        </div>
                      </div>
                      <div className="detail-card">
                        <div className="detail-card-header">
                          <div className="detail-card-icon">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                              <path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z" />
                              <path d="M12.5 7H11v6l5.25 3.15.75-1.23-4.5-2.67z" />
                            </svg>
                          </div>
                          <div className="detail-card-title">Time Slot</div>
                        </div>
                        <div className="detail-card-value">{formatTimeSlot(appointmentDetails.slot)}</div>
                      </div>
                    </div>
                  </div>

                  {/* Patient Information */}
                  {appointmentDetails.patient && appointmentDetails.patient.length > 0 && (
                    <div className="profile-section patient-section">
                      <div className="section-title">
                        <div className="section-icon">
                          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z" />
                          </svg>
                        </div>
                        <h2>Patient Information</h2>
                      </div>
                      <div className="patient-profile">
                        <div className="patient-avatar">{getInitials(appointmentDetails.patient[0].patient_name)}</div>
                        <div className="patient-info">
                          <h3>{appointmentDetails.patient[0].patient_name}</h3>
                          <p className="subtitle">Patient</p>
                        </div>
                      </div>
                      <div className="contact-grid">
                        <div className="contact-item">
                          <div className="contact-icon">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                              <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z" />
                            </svg>
                          </div>
                          <div className="contact-info">
                            <span className="label">Email Address</span>
                            <span className="value">{appointmentDetails.patient[0].patient_email}</span>
                          </div>
                        </div>
                        <div className="contact-item">
                          <div className="contact-icon">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                              <path d="M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z" />
                            </svg>
                          </div>
                          <div className="contact-info">
                            <span className="label">Phone Number</span>
                            <span className="value">{appointmentDetails.patient[0].patient_phone}</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Doctor Information */}
                  {appointmentDetails.doctor && appointmentDetails.doctor.length > 0 && (
                    <div className="profile-section doctor-section">
                      <div className="section-title">
                        <div className="section-icon">
                          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                          </svg>
                        </div>
                        <h2>Doctor Information</h2>
                      </div>
                      <div className="doctor-profile">
                        <div className="doctor-avatar">{getInitials(appointmentDetails.doctor[0].doctor_name)}</div>
                        <div className="doctor-info">
                          <h3>Dr. {appointmentDetails.doctor[0].doctor_name}</h3>
                          <p className="subtitle">Medical Doctor</p>
                        </div>
                      </div>
                      <div className="contact-grid">
                        <div className="contact-item">
                          <div className="contact-icon">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                              <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z" />
                            </svg>
                          </div>
                          <div className="contact-info">
                            <span className="label">Email Address</span>
                            <span className="value">{appointmentDetails.doctor[0].doctor_email}</span>
                          </div>
                        </div>
                        <div className="contact-item">
                          <div className="contact-icon">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                              <path d="M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z" />
                            </svg>
                          </div>
                          <div className="contact-info">
                            <span className="label">Phone Number</span>
                            <span className="value">{appointmentDetails.doctor[0].doctor_phone}</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Payment Information */}
                  {(appointmentDetails.price || appointmentDetails.payment_name) && (
                    <div className="profile-section payment-section">
                      <div className="section-title">
                        <div className="section-icon">
                          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z" />
                          </svg>
                        </div>
                        <h2>Payment Information</h2>
                      </div>
                      {appointmentDetails.price && (
                        <div className="payment-summary">
                          <div className="payment-amount">${appointmentDetails.price}</div>
                          <div className="payment-method">{appointmentDetails.payment_name || "Payment Method"}</div>
                        </div>
                      )}
                    </div>
                  )}
                </>
              ) : (
                <div className="loading-state">
                  <div className="loading-spinner"></div>
                  <p className="loading-text">Loading appointment details...</p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {openEditAppointment && (
        <div className="appointments-popup-container">
          <div className="appointments-popup-overlay"></div>
          <div className="appointments-popup">
            {renderDateButtons()}
            {formData.date && renderTimeSlots()}
            <div className="edit-appointment-action">
              <button className="appointments-cancel" onClick={handleCancelEditAppointment}>
                Cancel
              </button>
              <button className="appointments-save" onClick={handleConfirmEditAppointment} disabled={!formData.date || !formData.timeSlot}>
                Save
              </button>
            </div>
          </div>
        </div>
      )}
      <section className="dashboard-banner">
        <img className="dashboard-banner-img" src={bannerImg || "/placeholder.svg"} alt="dashboard-banner-img" />
        <h4>Patient Dashboard</h4>
        <div className="dashboard-overlay"></div>
      </section>
      {patientData ? (
        <section className="dashboard-content">
          <div className="patient-container">
            {imageValid ? <img id="patientImg" src={imagePath || "/placeholder.svg"} alt="Patient" /> : <img id="patientImg" width="150" height="150" src="https://img.icons8.com/ios-filled/200/004b91/user-male-circle.png" alt="user-male-circle" />}
            <div
              className="img-overlay"
              onClick={() => !imageUploading && document.getElementById("ipPatientImg").click()}
              style={{
                opacity: imageUploading ? 0.5 : 1,
                cursor: imageUploading ? "not-allowed" : "pointer",
              }}
            >
              <img width="30" height="30" src="https://img.icons8.com/ios-filled/200/FFFFFF/available-updates.png" alt="available-updates" />
              {imageUploading ? "Uploading..." : "Change Image"}
            </div>
            <input id="ipPatientImg" type="file" accept="image/*" onChange={handleImageChange} style={{ display: "none" }} disabled={imageUploading} />
            <div className="container-title">
              Personal Information
              {!openEditPatient ? (
                <div className="container-title-action">
                  <a onClick={() => setOpenEditPatient(true)}>Edit Information</a>/<a>Change Password</a>
                </div>
              ) : (
                <div className="container-title-action">
                  <a onClick={handleSavePatient}>Save</a>/<a onClick={handleCancelEdit}>Cancel</a>
                </div>
              )}
            </div>
            <div className="patient-info">
              {openEditPatient ? (
                <>
                  <div className="patient-info-item">
                    <h4>Full Name</h4>
                    <input type="text" name="patient_name" value={editFormData.patient_name} onChange={handleEditFormChange} required />
                  </div>
                  <div className="patient-info-item">
                    <h4>Date of Birth</h4>
                    <input type="text" name="patient_dob" value={editFormData.patient_dob} onChange={handleEditFormChange} placeholder="dd/mm/yyyy (e.g., 15/03/1990)" maxLength="10" required />
                  </div>
                  <div className="patient-info-item">
                    <h4>Gender</h4>
                    <select name="patient_gender" value={editFormData.patient_gender} onChange={handleEditFormChange} required>
                      <option value="Male">Male</option>
                      <option value="Female">Female</option>
                      <option value="Other">Other</option>
                    </select>
                  </div>
                  <div className="patient-info-item">
                    <h4>Email Address</h4>
                    <input type="email" name="patient_email" value={editFormData.patient_email} disabled style={{ backgroundColor: "#f5f5f5", cursor: "not-allowed" }} title="Email cannot be changed" />
                  </div>
                  <div className="patient-info-item">
                    <h4>Phone Number</h4>
                    <input type="text" name="patient_phone" value={editFormData.patient_phone} onChange={handleEditFormChange} placeholder="Enter 10 digits" maxLength="10" required />
                  </div>
                  <div className="patient-info-item">
                    <h4>Address</h4>
                    <input type="text" name="patient_address" value={editFormData.patient_address} onChange={handleEditFormChange} required />
                  </div>
                </>
              ) : (
                <>
                  <div className="patient-info-item">
                    <h4>Full Name</h4>
                    <p>{patientData.patient_name ?? ""}</p>
                  </div>
                  <div className="patient-info-item">
                    <h4>Date of Birth</h4>
                    <p>
                      {patientData.patient_dob
                        ? (() => {
                            let datePart = patientData.patient_dob;
                            if (patientData.patient_dob.includes("T")) {
                              datePart = patientData.patient_dob.split("T")[0];
                            }
                            return new Date(datePart).toLocaleDateString("en-GB"); // dd/mm/yyyy
                          })()
                        : ""}
                    </p>
                  </div>
                  <div className="patient-info-item">
                    <h4>Gender</h4>
                    <p>{patientData.patient_gender ?? ""}</p>
                  </div>
                  <div className="patient-info-item">
                    <h4>Email Address</h4>
                    <p>{patientData.patient_email ?? ""}</p>
                  </div>
                  <div className="patient-info-item">
                    <h4>Phone Number</h4>
                    <p>{patientData.patient_phone ?? ""}</p>
                  </div>
                  <div className="patient-info-item">
                    <h4>Address</h4>
                    <p>{patientData.patient_address ?? ""}</p>
                  </div>
                </>
              )}
            </div>
            {editFormData.patient_phone && editFormData.patient_phone.length !== 10 && <small style={{ color: "red" }}>Phone number must be exactly 10 digits</small>}
            <div className="container-title">Appointments & Medical Records</div>
            <div className="medical-info">
              <ul>
                <li className={`${appointmentVisible ? "active" : ""}`} onClick={toggleAppointmentVisible}>
                  Appointments
                </li>
                <li className={`${appointmentVisible ? "" : "active"}`} onClick={toggleAppointmentVisible}>
                  Medical Records
                </li>
              </ul>
              {appointmentVisible ? (
                <div className="appointment-container">
                  {currentAppointments.length > 0 ? (
                    currentAppointments.map((app) => (
                      <div className="appointment-item" key={app.appointment_id}>
                        <div className="appointment-item-header">
                          <h3>{new Date(app.appointment_date).toLocaleDateString()}</h3>
                          <span className="appointment-status">
                            {getStatusIcon(app.status)}
                            <p>{app.status}</p>
                          </span>
                        </div>
                        <p>
                          <strong>Doctor:</strong> {app.doctor && app.doctor.length > 0 ? app.doctor[0].doctor_name : "N/A"}
                        </p>
                        <p>
                          <strong>Department:</strong> {app.doctor && app.doctor.length > 0 && app.doctor[0].department && app.doctor[0].department.length > 0 ? app.doctor[0].department[0].department_name : "N/A"}
                        </p>
                        <p>
                          <strong>Staff Name:</strong> {app.staff && app.staff.length > 0 ? app.staff[0].staff_name : "N/A"}
                        </p>
                        <p>
                          <strong>Appointment Date:</strong> {new Date(app.medical_day).toLocaleDateString()}
                        </p>
                        <p>
                          <strong>Appointment Time:</strong> {formatTimeSlot(app.slot)}
                        </p>
                        <div className="appointment-action">
                          <button className="record-detail-button" onClick={() => handleViewAppointmentDetails(app)}>
                            Details
                          </button>
                          {app.status !== "Cancelled" && app.status !== "Completed" && (
                            <>
                              <button className="edit-appointment-button" onClick={() => handleOpenEditAppointment(app)} disabled={isEditCancelDisabled(app.medical_day, formatTimeSlot(app.slot))}>
                                Edit
                              </button>
                            </>
                          )}
                        </div>
                      </div>
                    ))
                  ) : (
                    <p>No appointments available.</p>
                  )}
                  {selectedAppointment && (
                    <div className="record-details-popup" role="dialog" aria-labelledby="appointment-details-title">
                      <div
                        className="record-details-overlay"
                        onClick={() => setSelectedAppointment(null)}
                        role="button"
                        aria-label="Close appointment details"
                        tabIndex={0}
                        onKeyDown={(e) => {
                          if (e.key === "Enter" || e.key === "Escape") {
                            setSelectedAppointment(null);
                          }
                        }}
                      ></div>
                      <div className="record-details-content">
                        <div className="popup-header">
                          <span className="popup-icon" role="img" aria-label="Appointment icon">
                            📅
                          </span>
                          <h3 id="appointment-details-title">Appointment Details</h3>
                        </div>
                        <div className="popup-body">
                          <div className="detail-row">
                            <span className="detail-label">Patient Name:</span>
                            <span className="detail-value">{patientData?.patient_name || "N/A"}</span>
                          </div>
                          <div className="detail-row">
                            <span className="detail-label">Booking Date:</span>
                            <span className="detail-value">
                              {selectedAppointment?.appointment_date
                                ? new Date(selectedAppointment.appointment_date).toLocaleDateString("en-US", {
                                    year: "numeric",
                                    month: "long",
                                    day: "numeric",
                                  })
                                : "N/A"}
                            </span>
                          </div>
                          <div className="detail-row">
                            <span className="detail-label">Appointment Date:</span>
                            <span className="detail-value">
                              {selectedAppointment?.medical_day
                                ? new Date(selectedAppointment.medical_day).toLocaleDateString("en-US", {
                                    year: "numeric",
                                    month: "long",
                                    day: "numeric",
                                  })
                                : "N/A"}
                            </span>
                          </div>
                          <div className="detail-row">
                            <span className="detail-label">Appointment Time:</span>
                            <span className="detail-value">{formatTimeSlot(selectedAppointment?.slot) || "N/A"}</span>
                          </div>
                          <div className="detail-row">
                            <span className="detail-label">Doctor:</span>
                            <span className="detail-value">{selectedAppointment?.doctor && selectedAppointment.doctor.length > 0 ? selectedAppointment.doctor[0].doctor_name : "No information available"}</span>
                          </div>
                          <div className="detail-row">
                            <span className="detail-label">Department:</span>
                            <span className="detail-value">{selectedAppointment?.doctor && selectedAppointment.doctor.length > 0 ? getDepartmentName(selectedAppointment.doctor[0].doctor_id) : "No information available"}</span>
                          </div>
                          <div className="detail-row">
                            <span className="detail-label">Staff Name:</span>
                            <span className="detail-value">{selectedAppointment?.staff && selectedAppointment.staff.length > 0 ? selectedAppointment.staff[0].staff_name : "No information available"}</span>
                          </div>
                          <div className="detail-row">
                            <span className="detail-label">Status:</span>
                            <span className="detail-value">{selectedAppointment?.status || "N/A"}</span>
                          </div>
                        </div>
                        <div className="popup-footer">
                          <button className="action-button" onClick={() => setSelectedAppointment(null)} aria-label="Close appointment details" autoFocus>
                            Close
                          </button>
                        </div>
                      </div>
                    </div>
                  )}
                  <div className="pagination-controls">
                    <a onClick={() => setCurrentAppointmentPage(1)}>
                      <img width="18" height="18" src="https://img.icons8.com/ios-filled/200/004b91/first-1.png" alt="first-1" />
                    </a>
                    <a onClick={() => setCurrentAppointmentPage((prev) => Math.max(prev - 1, 1))}>
                      <img width="18" height="18" src="https://img.icons8.com/ios-filled/200/004b91/back.png" alt="back" />
                    </a>
                    <span>
                      Page {currentAppointmentPage} of {totalAppointmentPages}
                    </span>
                    <a onClick={() => setCurrentAppointmentPage((prev) => Math.min(prev + 1, totalAppointmentPages))}>
                      <img width="18" height="18" src="https://img.icons8.com/ios-filled/200/004b91/forward.png" alt="forward" />
                    </a>
                    <a onClick={() => setCurrentAppointmentPage(totalAppointmentPages)}>
                      <img width="18" height="18" src="https://img.icons8.com/ios-filled/200/004b91/last-1.png" alt="last-1" />
                    </a>
                  </div>
                </div>
              ) : (
                <div className="record-container">
                  {currentRecords.length > 0 ? (
                    currentRecords.map((record) => (
                      <div key={record.record_id} className="record-item">
                        <div className="record-item-header">
                          <h3>{record.follow_up_date}</h3>
                        </div>
                        <p>
                          <strong>Department:</strong> {record.doctors && record.doctors.length > 0 ? getDepartmentName(record.doctors[0].department_id) : "No Department Info"}
                        </p>
                        <p>
                          <strong>Doctor:</strong> {record.doctors && record.doctors.length > 0 ? record.doctors[0].doctor_name : "No Doctor Info"}
                        </p>
                        <p>
                          <strong>Symptoms:</strong> {record.symptoms}
                        </p>
                        <p>
                          <strong>Diagnosis:</strong> {record.diagnosis}
                        </p>
                        <div className="record-action">
                          <button className="record-detail-button" onClick={() => handleViewDetails(record)}>
                            Details
                          </button>
                        </div>
                      </div>
                    ))
                  ) : (
                    <p>No records available.</p>
                  )}
                  {selectedRecord && (
                    <div className="record-details-popup" role="dialog" aria-labelledby="record-details-title">
                      <div
                        className="record-details-overlay"
                        onClick={() => setSelectedRecord(null)}
                        role="button"
                        aria-label="Close medical record details"
                        tabIndex={0}
                        onKeyDown={(e) => {
                          if (e.key === "Enter" || e.key === "Escape") {
                            setSelectedRecord(null);
                          }
                        }}
                      ></div>
                      <div className="record-details-content">
                        <div className="popup-header">
                          <span className="popup-icon" role="img" aria-label="Medical record icon">
                            📋
                          </span>
                          <h3 id="record-details-title">Medical Record Details</h3>
                        </div>
                        <div className="popup-body">
                          <div className="detail-row">
                            <span className="detail-label">Follow-up Date:</span>
                            <span className="detail-value">
                              {selectedRecord?.follow_up_date
                                ? new Date(selectedRecord.follow_up_date).toLocaleDateString("en-US", {
                                    year: "numeric",
                                    month: "long",
                                    day: "numeric",
                                  })
                                : "N/A"}
                            </span>
                          </div>
                          <div className="detail-row">
                            <span className="detail-label">Doctor:</span>
                            <span className="detail-value">{selectedRecord?.doctors && selectedRecord.doctors.length > 0 ? selectedRecord.doctors[0].doctor_name : "No information available"}</span>
                          </div>
                          <div className="detail-row">
                            <span className="detail-label">Department:</span>
                            <span className="detail-value">{selectedRecord?.doctors && selectedRecord.doctors.length > 0 ? getDepartmentName(selectedRecord.doctors[0].department_id) : "No information available"}</span>
                          </div>
                          <div className="detail-row">
                            <span className="detail-label">Symptoms:</span>
                            <span className="detail-value">{selectedRecord?.symptoms || "N/A"}</span>
                          </div>
                          <div className="detail-row">
                            <span className="detail-label">Diagnosis:</span>
                            <span className="detail-value">{selectedRecord?.diagnosis || "N/A"}</span>
                          </div>
                          <div className="detail-row">
                            <span className="detail-label">Prescription:</span>
                            <span className="detail-value">{selectedRecord?.prescription || "N/A"}</span>
                          </div>
                          {selectedRecord?.image && (
                            <div className="image-container">
                              <img src={selectedRecord.image} alt="Medical record scan" className="record-image" onError={(e) => (e.target.src = "https://via.placeholder.com/300x200?text=No+Image+Available")} loading="lazy" />
                            </div>
                          )}
                        </div>
                        <div className="popup-footer">
                          {selectedRecord?.image && (
                            <a href={selectedRecord.image} download className="action-button" aria-label="Download medical record image">
                              Download Image
                            </a>
                          )}
                        </div>
                      </div>
                    </div>
                  )}
                  <div className="pagination-controls">
                    <a onClick={() => setCurrentRecordPage(1)}>
                      <img width="18" height="18" src="https://img.icons8.com/ios-filled/200/004b91/first-1.png" alt="first-1" />
                    </a>
                    <a onClick={() => setCurrentRecordPage((prev) => Math.max(prev - 1, 1))}>
                      <img width="18" height="18" src="https://img.icons8.com/ios-filled/200/004b91/back.png" alt="back" />
                    </a>
                    <span>
                      Page {currentRecordPage} of {totalRecordPages}
                    </span>
                    <a onClick={() => setCurrentRecordPage((prev) => Math.min(prev + 1, totalRecordPages))}>
                      <img width="18" height="18" src="https://img.icons8.com/ios-filled/200/004b91/forward.png" alt="forward" />
                    </a>
                    <a onClick={() => setCurrentRecordPage(totalRecordPages)}>
                      <img width="18" height="18" src="https://img.icons8.com/ios-filled/200/004b91/last-1.png" alt="last-1" />
                    </a>
                  </div>
                </div>
              )}
            </div>
          </div>
        </section>
      ) : (
        <h1 className="dashboard-alert">To see the information, please sign in and refresh this page.</h1>
      )}
    </main>
  );
}

export default Dashboard;
