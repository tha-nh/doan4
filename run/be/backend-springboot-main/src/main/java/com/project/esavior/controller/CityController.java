package com.project.esavior.controller;

import com.project.esavior.dto.CityDTO;
import com.project.esavior.model.City;
import com.project.esavior.service.CityService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/city")
public class CityController {

    @Autowired
    private CityService cityService;

    @GetMapping
    public List<CityDTO> getAll() {
        // Chuyển đổi danh sách City sang danh sách CityDTO
        return cityService.findAll().stream()
                .map(city -> new CityDTO(
                        city.getCityId(),
                        city.getCityName(),
                        city.getCreatedAt(),
                        city.getUpdatedAt()
                ))
                .collect(Collectors.toList());
    }
}
