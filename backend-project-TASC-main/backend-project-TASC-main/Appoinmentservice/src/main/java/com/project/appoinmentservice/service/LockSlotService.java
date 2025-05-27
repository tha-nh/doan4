package com.project.appoinmentservice.service;

import com.project.appoinmentservice.dto.LockSlotDTO;
import com.project.appoinmentservice.dto.ResponseDTO;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public interface LockSlotService {
    public boolean isSlotLocked(LockSlotDTO lockSlotDTO);
    public void lockSlot(LockSlotDTO lockSlotDTO);
    public boolean checkIfCodeExists(String randomCode);
    public boolean updateKey(LockSlotDTO lockSlotDTO);
    public void getAllLockSlots();
    public ResponseEntity<ResponseDTO> getLockSlotByCode(LockSlotDTO lockSlotDTO);
}
