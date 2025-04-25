# 2025년 4월 팀 프로젝트
## RISC-V With AMBA APB BUS
### 팀원
- 박호윤, 지설윤  

### team anounce
- "testcode.mem" 파일에 테스트 머신코드 작성  
- "testcode.mem" 파일은 gitignore되어있으니 테스트코드는 프로젝트파일 최상단 트리에 C확장자로 저장하여 사용  
- 내 영역 외의 공간 임의 수정 말고 이슈 발생시 팀원과 상의(이슈리포트)  
- 주기적으로 진행상황 README 업데이트  
- README 수정시 가능하면 즉시 커밋/푸시  
- 비트스트림생성, 시뮬레이션, 회로합성시 생기는 파일 폴더는 gitignore되어있음  
- push해야하는데 ignore되서 파일이 탐색기에서 회색으로 보일경우 이슈리포트
    
#### team scatch board  
    마크다운 팁  
    탭 띄우고 써야 박스에 들어간다.  
    박스 안에서는 뉴라인 하면 뉴라인 된다.  
    박스 밖에서는 뉴라인 할때는 문장끝에 공백문자 두개(스페이스 두번 or 탭한번)를 넣고 뉴라인 하자.   
    제목은 맨 앞에 "#" 붙히면 된다.(갯수에 따라 깊이가 다르니 주의)  
    숫자 없는 항목(리스트)는 앞에 "*", "-", "+" 중 하날 쓴다. 
    숫자 있는 항목(리스트)는 앞에 "1.", "1)"
    마크다운 미리보기 단축키는 vsc 기본설정 기준 "ctrl+art+v"이다.  
    나도 마크다운 아는게 많지 않다. 애매하면 GPT와 코딩커뮤니티(스택오버플로우)로.  

### 진행상황 
#### 2025 04 25  
- RISC-V  
    - core  
        - R_Type
            - ADD 
            - SUB 
            - SLL 
            - SRL 
            - SRA 
            - SLT 
            - SLTU 
            - XOR 
            - OR 
            - AND
        - S_Type  
            - SW   
        - L_Type  
            - LW  
        - I_Type 
            - ADDI 
            - SLTI 
            - SLTUI 
            - XORI 
            - ORI 
            - ANDI 
            - SLLI 
            - SRLI 
            - SRAI
        - B_Type     
            - BEQ 
            - BNE 
            - BLT 
            - BGE 
            - BLTU 
            - BGEU  
        - LU_Type
        - AU_Type
        - J_Type
        - JR_Type 
    - ram   
    - rom   
    - AMBA APB BUS  
- Peripheral    
    - APB GPIO template  
    - GP FND BCD output  