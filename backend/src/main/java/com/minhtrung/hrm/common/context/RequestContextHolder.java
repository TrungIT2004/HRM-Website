package com.minhtrung.hrm.common.context;

public class RequestContextHolder {
    public static final ThreadLocal<RequestContext> requestContext = new ThreadLocal<>();

    public static void set(RequestContext ctx) {
        requestContext.set(ctx);
    }
    
    public static RequestContext get() {
        return requestContext.get();
    }
    
    public static void clear() {
        requestContext.remove();
    }
}
