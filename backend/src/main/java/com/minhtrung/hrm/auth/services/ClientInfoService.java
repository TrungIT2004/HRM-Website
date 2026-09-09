package com.minhtrung.hrm.auth.services;

import java.util.HashMap;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.minhtrung.hrm.auth.dtos.internals.ClientMetaData;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import nl.basjes.parse.useragent.UserAgent;
import nl.basjes.parse.useragent.UserAgentAnalyzer;

@Slf4j
@Service
public class ClientInfoService {
    private final RestTemplate restTemplate = new RestTemplate();

    private static final UserAgentAnalyzer USER_AGENT_ANALYZER = UserAgentAnalyzer
            .newBuilder()
            .hideMatcherLoadStats()
            .withCache(10000) 
            .build();

    public ClientMetaData getClientMetaData(HttpServletRequest request) {
        String userAgentString = request.getHeader("User-Agent");
        String ipAddr = extractRealIp(request);

        ClientMetaData clientMetaData = new ClientMetaData();

        Map<String, String> deviceInfo = getDeviceInfo(userAgentString);
        clientMetaData.setDeviceType(deviceInfo.get("deviceType"));
        clientMetaData.setDeviceOS(deviceInfo.get("deviceOS"));
        clientMetaData.setBrowser(deviceInfo.get("browser"));

        if (isLocalAddr(ipAddr)) {
            clientMetaData.setIpAddr("LocalHost");
            clientMetaData.setCountry("LocalHost");
            clientMetaData.setCity("LocalHost");
        } else {
            Map<String, String> geoLocInfo = getGeoLoc(ipAddr);
            clientMetaData.setIpAddr(ipAddr);
            clientMetaData.setCountry(geoLocInfo.get("country"));
            clientMetaData.setCity(geoLocInfo.get("city"));
        }

        log.info("Extract metadatas from headers");
        log.debug("Metadata: {}", clientMetaData);
        return clientMetaData;
    }
    
    public String extractRealIp(HttpServletRequest request) {
        // Cloudfare
        String ip = request.getHeader("CF-Connecting-IP");
        if (ip != null && !ip.isBlank())
            return ip;

        // Other VPNs
        ip = request.getHeader("X-Forwarded-For");
        if (ip != null && !ip.isBlank()) {
            int commaIndex = ip.indexOf(',');
            if (commaIndex != -1) {
                ip = ip.substring(0, commaIndex);
            }
            return ip.trim();
        }

        // Proxy: Nginx
        ip = request.getHeader("X-Real-IP");
        if (ip != null && !ip.isBlank())
            return ip;

        return request.getRemoteAddr();
    }
    
    private boolean isLocalAddr(String ipAddr) {
        if (ipAddr.startsWith("192.168")
            || ipAddr.startsWith("172.")
            || ipAddr.startsWith("10.")
            || ipAddr.startsWith("127.0.0.1")
            || ipAddr.equals("0:0:0:0:0:0:0:1")
            || ipAddr.equals("::1"))
            return true;
        return false;
    }
    
    private Map<String, String> getDeviceInfo(String userAgentString) {
        UserAgent agent = USER_AGENT_ANALYZER.parse(userAgentString);

        Map<String, String> deviceInfo = new HashMap<>();

        String deviceOS = agent.getValue("OperatingSystemNameVersion");
        String browser = agent.getValue("AgentName");
        String deviceType = agent.getValue("DeviceClass");

        if (deviceOS == null || deviceOS.isEmpty())
            deviceInfo.put("deviceOS", "UNKNOWN");
        else
            deviceInfo.put("deviceOS", deviceOS);


        if (browser == null || browser.isEmpty())
            deviceInfo.put("browser", "UNKNOWN");
        else
            deviceInfo.put("browser", browser);

        if (deviceType == null || deviceType.isEmpty())
            deviceInfo.put("deviceType", "UNKNOWN");
        else
            deviceInfo.put("deviceType", deviceType);

        return deviceInfo;
    }
    
    private Map<String, String> getGeoLoc(String ipAddr) {
        String url = "http://ip-api.com/json/" + ipAddr + "?fields=status,country,city";
        ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);
        Map<String, String> responseData = response.getBody();

        Map<String, String> geoLocInfo = new HashMap<>();

        if (responseData != null && "success".equals(responseData.get("status"))) {
            String country = responseData.get("country");
            String city = responseData.get("city");

            geoLocInfo.put("country", country);
            geoLocInfo.put("city", city);
        } else {
            geoLocInfo.put("country", "UNKNOWN");
            geoLocInfo.put("city", "UNKNOWN");
        }

        return geoLocInfo;
    }
}
 