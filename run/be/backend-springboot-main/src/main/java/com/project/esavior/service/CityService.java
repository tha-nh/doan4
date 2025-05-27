package com.project.esavior.service;

import com.project.esavior.model.City;
import com.project.esavior.repository.CityRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CityService {
    @Autowired
    private CityRepository cityRepository;
    public List<City> findAll() {
        return cityRepository.findAll();
    }
}
