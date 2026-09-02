section .data
    Key db                         ; ghi mã hex của key 32 byte hoặc 16 byte gì đó thì tùy
        db
        db
        db
    size_key equ $ - Key           ; đếm kích thước key
section .text
global LockRam
global _start
_start:
    pushad                         ; ghi nhớ trạng thái các thanh ghi 
    mov esi, Key                   ; địa chỉ chứa key
    mov edi, 0x10000000            ; địa chỉ đích để ghi key vào 
    mov ecx, size_key              ; copy kích thước key vào ecx
    cld                            ; xoá flag DF để chép tăng dần tránh chép lộn xộn 
    rep movsb                      ; copy dữ liệu từ esi sang edi
    wbinvd                         ; xả key từ cache qua ram chuẩn bị khoá

    mov eax, 0x10000000            ; địa chỉ bắt đầu 
    mov ecx, 0x10000               ; kích thước muốn khoá là 0x10000 = 64kb
    call LockRam                   ; gọi hàm LockRam bên dưới 
    popad                          ; lấy tất cả về từ stack
    ret                            ; trả con trỏ về cho bios làm gì thì làm
LockRam:
    push eax                       ; đẩy địa chỉ bắt đầu vào stack
    push ebx                       ; đẩy địa chỉ kết thúc vào stack
    push ecx                       ; đẩy tham số kích thước vào stack
    push edx                       ; làm vậy cho an toàn

    mov ebx, eax                   ; copy địa chỉ bắt đầu vào ebx để tính toán vùng cần khoá tránh sai lệch địa chỉ của thanh ghi eax
    add ebx, ecx                   ; cộng địa chỉ bắt đầu và kích thước lại
    dec ebx                        ; lấy kết quả -1 theo đúng công thức

    mov ecx, eax                   ; Lưu địa chỉ bắt đầu vào ecx

    mov eax, 0x80000084            ; nạp mã địa chỉ PCI 0x84 
    mov edx, ecx                   ; copy địa chỉ bắt đầu vào edx
    call WritePciRegister32        ; gọi hàm ghi 

  
    mov eax, 0x80000088            ; nạp mã địa chỉ PCI 0x88
    mov edx, ebx                   ; ghi địa chỉ kết thúc vào edx
    call WritePciRegister32        ; gọi hàm ghi 

    
    mov eax, 0x8000008C            ; nạp mã địa chỉ thanh ghi 0x8C
    mov edx, 0x00000001            ; nạp lệnh bit 0 thành bit 1 ,cho phép os đọc ,nếu muốn không cho phép đọc thì chuyển thành 0x00000000
    call WritePciRegister32        ; gọi hàm ghi 

    
    mov eax, 0x8000008C            ; nạp mã địa chỉ thanh ghi 0x8C 
    mov edx, 0x80000001            ; đóng băng thanh ghi cấm os ghi vào 
    call WritePciRegister32        ; gọi hàm ghi 

    pop edx                        ; lấy giá trị về từ stack 
    pop ecx                        ; y chang ,bên dưới cũng vậy 
    pop ebx
    pop eax
    ret                            ; trả về hàm start 

WritePciRegister32:
    push edx                       ; đẩy lên stack tiếp 
    


    mov dx, 0xCF8                  ; nạp mã địa chỉ PCI 0xCF8 
    out dx, eax                    ; ghi địa chỉ bắt đầu vào 0xCF8 


    pop eax                        ; trả về từ stack
    mov dx, 0xCFC                  ; nạp mã của cổng 0xCFC vào dx (là cổng duy nhất cho phép chipset và cpu giao tiếp truyền data với nhau)
    out dx, eax                    ; ghi địa chỉ bât đầu thông qua cổng CFC để vào các thanh ghi phía trên
    
    ret                            ; trả về hàm ghi
