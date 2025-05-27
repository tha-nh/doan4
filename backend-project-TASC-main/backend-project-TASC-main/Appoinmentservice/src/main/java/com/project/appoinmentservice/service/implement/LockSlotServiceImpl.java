package com.project.appoinmentservice.service.implement;

import com.project.appoinmentservice.dto.LockSlotDTO;
import com.project.appoinmentservice.dto.ResponseDTO;
import com.project.appoinmentservice.service.LockSlotService;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

@Service
public class LockSlotServiceImpl implements LockSlotService {

    // Sử dụng ConcurrentHashMap để lưu trữ thông tin về các slot đã bị khóa
    private ConcurrentHashMap<String, LockSlotDTO> lockedSlots = new ConcurrentHashMap<>();

    // Kiểm tra xem slot có bị khóa hay không
    @Override
    public boolean isSlotLocked(LockSlotDTO lockSlotDTO) {
        String key = generateKey(lockSlotDTO);
        LockSlotDTO existingLockSlot = lockedSlots.get(key);
        System.out.println(existingLockSlot);
        return existingLockSlot == null;
    }

    @Override
    public boolean checkIfCodeExists(String randomCode) {
        for (LockSlotDTO lockSlot : lockedSlots.values()) {
            if (lockSlot.getRandomCode().equals(randomCode)) {
                return true;
            }
        }
        return false;
    }
    public boolean updateKey(LockSlotDTO lockSlotDTO) {
        String newKey = generateKey(lockSlotDTO);  // Khóa mới từ LockSlotDTO mới
        String randomCode = lockSlotDTO.getRandomCode();  // randomCode từ LockSlotDTO

        // Duyệt qua Map để tìm LockSlot có randomCode trùng
        for (ConcurrentHashMap.Entry<String, LockSlotDTO> entry : lockedSlots.entrySet()) {
            if (entry.getValue().getRandomCode().equals(randomCode)) {
                // Xóa key cũ khỏi Map (dựa trên khóa cũ)
                lockedSlots.remove(entry.getKey());
                lockedSlots.put(newKey, entry.getValue());
                return true;  // Cập nhật thành công
            }
        }

        return false;  // Không tìm thấy randomCode tương ứng
    }

    @Override
    public void getAllLockSlots() {
        for (ConcurrentHashMap.Entry<String, LockSlotDTO> entry : lockedSlots.entrySet()) {
            System.out.println(entry.getKey() + "  : " + entry.getValue().getRandomCode());
        }
    }

    @Override
    public ResponseEntity<ResponseDTO> getLockSlotByCode(LockSlotDTO lockSlotDTO) {
        System.out.println(lockSlotDTO.toString());
        boolean isSlotLocked = isSlotLocked(lockSlotDTO);  // Kiểm tra slot đã được khóa chưa
        boolean isCodeRandom = checkIfCodeExists(lockSlotDTO.getRandomCode());  // Kiểm tra random code

        System.out.println("slot locked: " + isSlotLocked);
        System.out.println("isCodeRandom : " + isCodeRandom);

        // Chuyển điều kiện thành giá trị có thể so sánh với switch-case
        String caseSwitch = (isCodeRandom ? "RANDOM" : "NOT_RANDOM") + (isSlotLocked ? "_LOCKED" : "_UNLOCKED");

        switch (caseSwitch) {
            case "RANDOM_LOCKED":
                updateKey(lockSlotDTO);
                System.out.println("Đã khóa slot mới, nhả slot cũ!");
                getAllLockSlots();
                return ResponseEntity.ok(new ResponseDTO(200, "Đã khóa slot mới, nhả slot cũ!"));

            case "RANDOM_UNLOCKED":
                System.out.println("Slot này đã được khóa trước đó, không khóa lại!");
                getAllLockSlots();
                return ResponseEntity.status(200).body(new ResponseDTO(400, "Slot này đã được khóa trước đó, đã mở slot . vui lòng chọn lại"));

            case "NOT_RANDOM_LOCKED":
                lockSlot(lockSlotDTO);
                System.out.println("Slot đã được lock!");
                getAllLockSlots();
                return ResponseEntity.ok(new ResponseDTO(200, "Slot đã được khóa!"));

            case "NOT_RANDOM_UNLOCKED":
                System.out.println("Slot này đã khóa, vui lòng chọn slot khác!");
                getAllLockSlots();
                return ResponseEntity.status(200).body(new ResponseDTO(409, "Slot này đã khóa, vui lòng chọn slot khác!"));

            default:
                return ResponseEntity.status(200).body(new ResponseDTO(500, "Lỗi không xác định"));
        }
    }

    // Khóa slot
    @Override
    public void lockSlot(LockSlotDTO lockSlotDTO) {
        String key = generateKey(lockSlotDTO);
        // Khóa slot trong 5 phút
        LockSlotDTO lockSlot = new LockSlotDTO();
        lockSlot.setRandomCode(lockSlotDTO.getRandomCode());
        lockedSlots.put(key, lockSlotDTO);
        for (ConcurrentHashMap.Entry<String, LockSlotDTO> entry : lockedSlots.entrySet()) {
            String key1 = entry.getKey();
            System.out.println("Key: " + key1 + ", Value: " + entry.getValue().getRandomCode());
        }

        new Thread(() -> {
            try {
                TimeUnit.MINUTES.sleep(5);
                unlockedSlot(lockSlotDTO);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }).start();
    }

    private void unlockedSlot(LockSlotDTO lockSlotDTO) {
        String key = generateKey(lockSlotDTO);
        lockedSlots.remove(key);
    }

    // Tạo key duy nhất để lưu trong ConcurrentHashMap
    private String generateKey(LockSlotDTO lockSlotDTO) {
        String key = lockSlotDTO.getDoctorId().toString() + lockSlotDTO.getMedicalDay().toString()  + lockSlotDTO.getSlot().toString();
        System.out.println("key được tạo: " + key);
        return key;
    }



}
