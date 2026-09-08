package com.minhtrung.social_app.common.context;

import com.minhtrung.social_app.auth.dtos.internals.ClientMetaData;
import com.minhtrung.social_app.auth.dtos.internals.TokenPayload;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class RequestContext {
    private ClientMetaData metaData;
    private TokenPayload tokenPayload;
}
