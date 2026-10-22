package com.minhtrung.hrm.auth.services;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.minhtrung.hrm.auth.dtos.internals.ClientMetaData;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class ClientInfoService {
    private final RestTemplate restTemplate = new RestTemplate();

    // Cache IP -> geo (giong UA cache 10k ben tren): user goi 10 req/phut
    // nhung chi ton 1 call ip-api cho den khi restart.
    private final Map<String, Map<String, String>> geoCache = new ConcurrentHashMap<>();

    public ClientMetaData getClientMetaData(HttpServletRequest request) {
        String userAgentString = request.getHeader("User-Agent");
        String ipAddr = extractRealIp(request);

        ClientMetaData clientMetaData = new ClientMetaData();

        Map<String, String> deviceInfo = getDeviceInfo(userAgentString);
        clientMetaData.setDeviceType(deviceInfo.get("deviceType"));
        clientMetaData.setDeviceOS(deviceInfo.get("deviceOS"));
        clientMetaData.setBrowser(deviceInfo.get("browser"));
        clientMetaData.setUserAgentRaw(userAgentString);

        if (isLocalAddr(ipAddr)) {
            clientMetaData.setIpAddr("LocalHost");
            clientMetaData.setCountry("LocalHost");
            clientMetaData.setCity("LocalHost");
            clientMetaData.setIsp("Local Network");
        } else {
            Map<String, String> geoLocInfo = getGeoLoc(ipAddr);
            clientMetaData.setIpAddr(ipAddr);
            clientMetaData.setCountry(geoLocInfo.get("country"));
            clientMetaData.setCity(geoLocInfo.get("city"));
            clientMetaData.setIsp(geoLocInfo.get("isp"));
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
    
    // ponytail: contains() thay Yauaa 15MB — session UI chỉ cần browser/OS
    // tên + deviceType chứa phone|mobile|tablet (AdminWorkspace soi chuỗi này
    // để chọn icon). Ceiling: UA lạ/nhúng version chi tiết -> nâng cấp parser
    // khi admin báo "Unknown" nhiều.
    private Map<String, String> getDeviceInfo(String userAgentString) {
        String ua = userAgentString == null ? "" : userAgentString;
        String low = ua.toLowerCase();

        String browser;
        if (low.contains("edg"))
            browser = "Edge";
        else if (low.contains("chrome") || low.contains("crios"))
            browser = "Chrome";
        else if (low.contains("firefox") || low.contains("fxios"))
            browser = "Firefox";
        else if (low.contains("safari"))
            browser = "Safari";
        else
            browser = "UNKNOWN";

        String deviceOS;
        if (low.contains("windows nt"))
            deviceOS = withVersion("Windows", versionAfter(low, "windows nt "));
        else if (low.contains("android"))
            deviceOS = withVersion("Android", versionAfter(low, "android "));
        else if (low.contains("iphone") || low.contains("ipad"))
            deviceOS = withVersion("iOS", versionAfter(low, "os "));
        else if (low.contains("mac os x"))
            deviceOS = withVersion("Mac OS X", versionAfter(low, "mac os x "));
        else if (low.contains("linux"))
            deviceOS = "Linux";
        else
            deviceOS = "UNKNOWN";

        String deviceType;
        if (low.contains("tablet") || low.contains("ipad"))
            deviceType = "Tablet";
        else if (low.contains("mobile") || low.contains("phone")
                || low.contains("android") || low.contains("iphone"))
            deviceType = "Mobile";
        else
            deviceType = "Desktop";

        Map<String, String> deviceInfo = new HashMap<>();
        deviceInfo.put("deviceOS", deviceOS);
        deviceInfo.put("browser", browser);
        deviceInfo.put("deviceType", deviceType);
        return deviceInfo;
    }

    private static String withVersion(String name, String version) {
        return version.isEmpty() ? name : name + " " + version;
    }

    private static String versionAfter(String low, String token) {
        int i = low.indexOf(token);
        if (i < 0)
            return "";
        int s = i + token.length();
        int e = s;
        while (e < low.length()
                && (Character.isDigit(low.charAt(e)) || low.charAt(e) == '.'
                    || low.charAt(e) == '_'))
            e++;
        String v = low.substring(s, e).replace('_', '.');
        int dot = v.indexOf('.');
        if (dot >= 0)
            dot = v.indexOf('.', dot + 1);
        return dot >= 0 ? v.substring(0, dot) : v;
    }
    
    private Map<String, String> getGeoLoc(String ipAddr) {
        Map<String, String> cached = geoCache.get(ipAddr);
        if (cached != null)
            return cached;

        Map<String, String> geoLocInfo = new HashMap<>();
        try {
            String url = "http://ip-api.com/json/" + ipAddr + "?fields=status,country,city,isp";
            ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);
            Map<String, String> responseData = response.getBody();

            if (responseData != null && "success".equals(responseData.get("status"))) {
                geoLocInfo.put("country", responseData.get("country"));
                geoLocInfo.put("city", responseData.get("city"));
                geoLocInfo.put("isp", responseData.get("isp"));
            } else {
                geoLocInfo.put("country", "UNKNOWN");
                geoLocInfo.put("city", "UNKNOWN");
                geoLocInfo.put("isp", "UNKNOWN");
            }
        } catch (Exception e) {
            // GeoIP chi la metadata session (best-effort): 429/timeout
            // khong bao gio duoc lam fail request chinh.
            log.warn("GeoIP lookup failed for {}: {}", ipAddr, e.getMessage());
            geoLocInfo.put("country", "UNKNOWN");
            geoLocInfo.put("city", "UNKNOWN");
            geoLocInfo.put("isp", "UNKNOWN");
        }

        // ponytail: clear thay vi LRU that — du cho restart cycle ngan cua demo; dung Caffeine khi can TTL that.
        if (geoCache.size() >= 10000)
            geoCache.clear();
        geoCache.put(ipAddr, geoLocInfo);
        return geoLocInfo;
    }
}
 