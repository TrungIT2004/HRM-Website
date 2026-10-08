package com.minhtrung.hrm.employees.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.OffsetDateTime;
import java.util.UUID;

@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "user_bank_accounts")
public class UserBankAccount {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    // 1 nhân viên có nhiều tài khoản -> không @MapsId, userId là FK thường
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", referencedColumnName = "userId",
            foreignKey = @ForeignKey(name = "fk_user_bank_account_user"))
    @JsonIgnore
    private User user;

    private String bankName;

    // BIN để tích hợp API chuyển tiền sau này (VCB 970436, TCB 970407...)
    private String bankCode;

    private String accountNumber;

    // Tên chủ tài khoản phải khớp CCCD/hồ sơ
    private String accountHolderName;

    // Tài khoản nhận lương. DB có partial unique index: mỗi user tối đa 1 default
    @Column(name = "is_default")
    private Boolean isDefault;

    @Column(name = "created_at")
    private OffsetDateTime createdAt;

    /** Tên tài khoản dùng khi trả lương: ưu tiên is_default, không có thì tự chọn. */
    public static UserBankAccount pickDefault(java.util.List<UserBankAccount> list) {
        if (list == null || list.isEmpty()) return null;
        return list.stream()
                .filter(b -> Boolean.TRUE.equals(b.getIsDefault()))
                .findFirst()
                .orElse(list.get(0));
    }
}
