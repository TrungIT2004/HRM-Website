package com.minhtrung.social_app.auth.dtos.internals;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class ClientMetaData {
    private String deviceType;
    private String deviceOS;
    private String browser;
    private String ipAddr;
    private String country;
    private String city;
}
