import streamlit as st
from questions import (
    COGNITIVE_QUESTIONS, 
    SUBJECT_QUESTIONS, 
    HOBBY_QUESTIONS, 
    GOAL_QUESTIONS, 
    FINANCIAL_QUESTIONS,
    MBTI_DESCRIPTIONS
)

# ---------------------------------------------------------
# 1. การตั้งค่าหน้าตาเว็บ (Page Configuration)
# ---------------------------------------------------------
st.set_page_config(
    page_title="ระบบวิเคราะห์เส้นทางเรียนและอาชีพตามตัวตน",
    page_icon="🎓",
    layout="wide"
)

# ---------------------------------------------------------
# 2. จัดการ Session State (ระบบจำสถานะแบบ Step-by-Step)
# ---------------------------------------------------------
if 'step' not in st.session_state:
    st.session_state.step = 1
if 'mbti_result' not in st.session_state:
    st.session_state.mbti_result = "ENTP"
if 'top_functions' not in st.session_state:
    st.session_state.top_functions = []
if 'user_preferences' not in st.session_state:
    st.session_state.user_preferences = {}

# สเกลการตอบคำถาม 1-5 (Likert Scale)
SCALE_OPTIONS = {
    "1 - ไม่ตรงเลย": 1,
    "2 - ไม่ค่อยตรง": 2,
    "3 - ปานกลาง / ไม่แน่ใจ": 3,
    "4 - ค่อนข้างตรง": 4,
    "5 - ตรงมากที่สุด": 5
}

# ---------------------------------------------------------
# HELPER FUNCTIONS: ดึงอาชีพเด่นหลักตาม MBTI โดยตรง (Step 2)
# ---------------------------------------------------------
def get_custom_career(mbti_type):
    mbti_careers = {
        "INTJ": {
            "title": "นักวางกลยุทธ์ / นักวิเคราะห์ระบบ (Strategic Analyst & System Architect)", 
            "icon": "♟️", 
            "desc": "เน้นการคิดวิเคราะห์เชิงลึก การวางแผนระยะยาว และการแก้ปัญหาซับซ้อนด้วยตรรกะที่เป็นระบบ"
        },
        "INTP": {
            "title": "นักคิดทฤษฎี / นักวิจัยเชิงตรรกะ (Theoretical Researcher & Logician)", 
            "icon": "🔬", 
            "desc": "เน้นการวิเคราะห์แนวคิดแปลกใหม่ การทดลองสมมติฐาน และการพัฒนาระบบเชิงทฤษฎีอย่างสมบูรณ์แบบ"
        },
        "ENTJ": {
            "title": "ผู้บริหารองค์กร / นักวางแผนเชิงพาณิชย์ (Executive Director & Strategist)", 
            "icon": "💼", 
            "desc": "เน้นการนำทีม การบริหารจัดการทรัพยากร การตัดสินใจเชิงกลยุทธ์ และการขับเคลื่อนเป้าหมายสเกลใหญ่"
        },
        "ENTP": {
            "title": "นักคิดค้นนวัตกรรม / ที่ปรึกษาการแก้ปัญหา (Innovator & Consultant)", 
            "icon": "💡", 
            "desc": "เน้นการท้าทายกรอบความคิดเดิม การคิดค้นแนวคิดล้ำยุค และการแก้ปัญหาเฉพาะหน้าด้วยตรรกะ"
        },
        "INFJ": {
            "title": "จิตแพทย์ / ที่ปรึกษาเชิงจิตวิทยา (Psychologist & Counselor)", 
            "icon": "🧠", 
            "desc": "เน้นการรับฟังเชิงลึก การทำความเข้าใจมิติทางอารมณ์และจิตใจ และการชี้แนวทางให้ผู้คนเติบโต"
        },
        "INFP": {
            "title": "นักเขียน / นักสื่อสารอุดมคติ (Visionary Writer & Humanist)", 
            "icon": "📖", 
            "desc": "เน้นการถ่ายทอดเรื่องราวที่มีความหมายลึกซึ้ง งานเชิงคุณค่า และการสื่อสารอุดมคติส่วนตัว"
        },
        "ENFJ": {
            "title": "นักพัฒนาศักยภาพมนุษย์ / นักขับเคลื่อนสังคม (Transformational Leader)", 
            "icon": "🤝", 
            "desc": "เน้นการสร้างแรงบันดาลใจ การสื่อสารต่อหน้าคนจำนวนมาก และการสร้างความเปลี่ยนแปลงในสังคม"
        },
        "ENFP": {
            "title": "นักสร้างสรรค์แรงบันดาลใจ / นักสื่อสารมวลชน (Creative Communicator)", 
            "icon": "🌟", 
            "desc": "เน้นงานที่มีความหลากหลาย มีอิสระ การเชื่อมโยงผู้คน และการค้นหาความเป็นไปได้ใหม่ๆ"
        },
        "ISTJ": {
            "title": "นักตรวจสอบบัญชี / ผู้เชี่ยวชาญด้านระบบมาตรฐาน (Quality Auditor & Specialist)", 
            "icon": "📋", 
            "desc": "เน้นความแม่นยำ ยึดมั่นในกฎระเบียบ การจัดการข้อมูลอย่างเป็นระบบ และความน่าเชื่อถือ"
        },
        "ISFJ": {
            "title": "ผู้ดูแลระบบการบริการ / บุคลากรสนับสนุน (Operations Support Specialist)", 
            "icon": "🛡️", 
            "desc": "เน้นการใส่ใจรายละเอียด การดูแลความเรียบร้อย และการสนับสนุนช่วยเหลือผู้อื่นด้วยความประณีต"
        },
        "ESTJ": {
            "title": "ผู้จัดการฝ่ายปฏิบัติการ / นักบริหารจัดการ (Operations Manager)", 
            "icon": "📊", 
            "desc": "เน้นการตั้งเป้าหมายที่ชัดเจน การควบคุมกระบวนการทำงานให้มีประสิทธิภาพ และการจัดระเบียบองค์กร"
        },
        "ESFJ": {
            "title": "นักบริหารความสัมพันธ์องค์กร / นักประสานงานชุมชน (Community Coordinator)", 
            "icon": "🏠", 
            "desc": "เน้นการสร้างความร่วมมือในทีม การดูแลสารพัดสุข และการตอบโจทย์ความต้องการของผู้คน"
        },
        "ISTP": {
            "title": "วิศวกรเทคนิค / ผู้เชี่ยวชาญการแก้ปัญหาเฉพาะหน้า (Technical Troubleshooter)", 
            "icon": "🛠️", 
            "desc": "เน้นการลงมือทำจริง การวิเคราะห์กลไก และการแก้ปัญหาเฉพาะหน้าทางเทคนิคที่ต้องใช้ทักษะสูง"
        },
        "ISFP": {
            "title": "นักสร้างสรรค์สุนทรียภาพ / ศิลปินอิสระ (Aesthetic Creator)", 
            "icon": "🎨", 
            "desc": "เน้นงานที่ถ่ายทอดความงาม อารมณ์ความรู้สึก และการทำงานอย่างมีอิสระตามจังหวะของตนเอง"
        },
        "ESTP": {
            "title": "นักแก้ปัญหาความเสี่ยง / ผู้ประกอบการเชิงรุก (Risk & Crisis Manager)", 
            "icon": "⚡", 
            "desc": "เน้นการตัดสินใจรวดเร็ว ความท้าทาย การลงมือปฏิบัติจริงในสถานการณ์สด และการเห็นผลทันที"
        },
        "ESFP": {
            "title": "นักสร้างความบันเทิง / ผู้เชี่ยวชาญด้านประสบการณ์ (Event & Experience Specialist)", 
            "icon": "🎭", 
            "desc": "เน้นปฏิสัมพันธ์กับผู้คน การสร้างบรรยากาศสดใส และการดึงดูดความสนใจจากผู้ชม"
        }
    }
    
    return mbti_careers.get(mbti_type, {
        "title": "นักวิเคราะห์และพัฒนาตามตัวตน", 
        "icon": "🎯", 
        "desc": "เน้นการนำจุดแข็งทางบุคลิกภาพไปประยุกต์ใช้ในสายงานที่เหมาะสม"
    })

# ---------------------------------------------------------
# STEP 1: ประเมิน Cognitive Functions (80 ข้อ)
# ---------------------------------------------------------
if st.session_state.step == 1:
    st.title("🧩 ขั้นตอนที่ 1: ประเมินบุคลิกภาพ (Cognitive Functions 80 ข้อ)")
    st.write("โปรดเลือกสเกลที่ตรงกับความเป็นจริงของคุณมากที่สุด (1 = ไม่ตรงเลย, 5 = ตรงมากที่สุด)")
    
    with st.form("mbti_form"):
        raw_answers = {}
        for idx, q in enumerate(COGNITIVE_QUESTIONS, 1):
            st.markdown(f"**ข้อที่ {idx}:** {q['text']}")
            ans = st.radio(
                f"ระดับความตรง (ข้อ {idx}):", 
                options=list(SCALE_OPTIONS.keys()), 
                index=2, 
                key=f"cog_{q['id']}",
                horizontal=True
            )
            raw_answers[q['id']] = {"func": q["func"], "score": SCALE_OPTIONS[ans]}
            st.markdown("<hr style='margin: 0.5rem 0 1.5rem 0;'>", unsafe_allow_html=True)
            
        submitted = st.form_submit_button("🚀 ประมวลผลและคำนวณตรรกศาสตร์ MBTI (Step 1)")
        
        if submitted:
            func_scores = {"Ne": 0, "Ni": 0, "Se": 0, "Si": 0, "Te": 0, "Ti": 0, "Fe": 0, "Fi": 0}
            for item in raw_answers.values():
                func_scores[item["func"]] += item["score"]

            func_percentages = {func: round((score / 50) * 100, 1) for func, score in func_scores.items()}
            sorted_funcs = sorted(func_scores.items(), key=lambda x: x[1], reverse=True)

            dom_func = max(func_scores, key=func_scores.get)

            possible_aux = []
            if dom_func in ["Ne", "Se"]:
                possible_aux = ["Ti", "Fi"]
            elif dom_func in ["Ni", "Si"]:
                possible_aux = ["Te", "Fe"]
            elif dom_func in ["Te", "Fe"]:
                possible_aux = ["Ni", "Si"]
            elif dom_func in ["Ti", "Fi"]:
                possible_aux = ["Ne", "Se"]

            aux_func = max(possible_aux, key=lambda f: func_scores[f])

            opposite_map = {
                "Ne": "Si", "Si": "Ne",
                "Ni": "Se", "Se": "Ni",
                "Te": "Fi", "Fi": "Te",
                "Ti": "Fe", "Fe": "Ti"
            }
            tertiary_func = opposite_map[aux_func]
            inferior_func = opposite_map[dom_func]

            st.session_state.func_scores = func_scores
            st.session_state.func_percentages = func_percentages
            st.session_state.sorted_funcs = sorted_funcs
            
            st.session_state.mbti_stack = {
                "Dom": dom_func,
                "Aux": aux_func,
                "Tert": tertiary_func,
                "Inf": inferior_func
            }

            type_mapping = {
                ("Ne", "Ti"): "ENTP", ("Ne", "Fi"): "ENFP",
                ("Ni", "Te"): "INTJ", ("Ni", "Fe"): "INFJ",
                ("Se", "Ti"): "ESTP", ("Se", "Fi"): "ESFP",
                ("Si", "Te"): "ISTJ", ("Si", "Fe"): "ISFJ",
                ("Te", "Ni"): "ENTJ", ("Te", "Si"): "ESTJ",
                ("Ti", "Ne"): "INTP", ("Ti", "Se"): "ISTP",
                ("Fe", "Ni"): "ENFJ", ("Fe", "Si"): "ESFJ",
                ("Fi", "Ne"): "INFP", ("Fi", "Se"): "ISFP"
            }
            
            mbti_code = type_mapping.get((dom_func, aux_func), "ENTP")
            st.session_state.mbti_result = mbti_code
            
            st.session_state.step = 2
            st.rerun()

# ---------------------------------------------------------
# STEP 2: สรุปผลลัพธ์ MBTI และอาชีพเด่นประจำบุคลิกภาพ
# ---------------------------------------------------------
elif st.session_state.step == 2:
    st.title("🌟 ขั้นตอนที่ 2: สรุปผลลัพธ์บุคลิกภาพและตรรกศาสตร์การคำนวณ")
    
    mbti = st.session_state.mbti_result
    info = MBTI_DESCRIPTIONS.get(mbti, MBTI_DESCRIPTIONS["ENTP"])
    sorted_funcs = st.session_state.get("sorted_funcs", [])
    func_pct = st.session_state.get("func_percentages", {})
    
    st.success(f"### ผลการวิเคราะห์: บุคลิกภาพของคุณคือ **{mbti}** ({info['title']})")
    st.info(f"**ลักษณะตัวตน:** {info['desc']}")
    
    st.subheader("📊 ตรรกศาสตร์การคำนวณ Cognitive Functions (คะแนนเต็ม 50 คะแนน)")
    
    col_chart, col_rank = st.columns([3, 2])
    
    with col_chart:
        st.markdown("**ระดับความเข้มข้นของแต่ละฟังก์ชัน (%):**")
        for func_code, score in sorted_funcs:
            pct = func_pct.get(func_code, 0)
            st.write(f"**{func_code}**: {score}/50 คะแนน ({pct}%)")
            st.progress(pct / 100)
            
    with col_rank:
        st.markdown("**การจัดลำดับตามทฤษฎี (Cognitive Stack):**")
        stack = st.session_state.get("mbti_stack", {})
        if stack:
            st.write(f"🥇 **Dominant (ฟังก์ชันหลัก):** `{stack['Dom']}` ({func_pct[stack['Dom']]}%)")
            st.write(f"🥈 **Auxiliary (ฟังก์ชันรอง):** `{stack['Aux']}` ({func_pct[stack['Aux']]}%)")
            st.write(f"🥉 **Tertiary (ฟังก์ชันลำดับสาม):** `{stack['Tert']}` ({func_pct[stack['Tert']]}%)")
            st.write(f"⚓ **Inferior (จุดที่ต้องพัฒนา):** `{stack['Inf']}` ({func_pct[stack['Inf']]}%)")
            
    st.markdown("---")

    # ---------------------------------------------------------
    # แสดงผลอาชีพเด่นหลักตาม MBTI โดยตรง
    # ---------------------------------------------------------
    custom_career = get_custom_career(mbti)

    st.markdown("### 🎯 แนวทางอาชีพเด่นตามบุคลิกภาพ (MBTI Primary Career Spectrum)")
    st.info(f"""
    ### {custom_career['icon']} {custom_career['title']}
    
    **จุดเด่นการทำงาน:** {custom_career['desc']}
    
    *(หมายเหตุ: ในขั้นตอนถัดไป คุณสามารถระบุวิชาที่ชอบและเงื่อนไขการเงิน เพื่อให้ระบบเจาะจงอาชีพและสถาบันการศึกษาได้ตรงใจยิ่งขึ้น)*
    """)
    
    # ---------------------------------------------------------
    # แสดงตรรกศาสตร์สไตล์ ม.4 (Propositions & Truth Logic)
    # ---------------------------------------------------------
    st.markdown("---")
    with st.expander("📚 คลิกเพื่อดูตรรกศาสตร์การคำนวณ (ระดับ ม.4: เรื่องประพจน์และเงื่อนไข)"):
        st.markdown("### 1. การกำหนดประพจน์ (Propositions)")
        st.write("* ให้ **Score(f)** แทน คะแนนของฟังก์ชัน f")
        st.write("* ให้ประพจน์ **P**: *ฟังก์ชัน A มีคะแนนสูงที่สุด*")
        
        st.markdown("---")

        st.markdown("### 2. เงื่อนไขทางตรรกศาสตร์ในการหา Dominant (ฟังก์ชันหลัก)")
        st.latex(r"\text{Dom} = A \iff \forall f \, (\text{Score}(A) \ge \text{Score}(f))")
        st.caption("แปลว่า: ฟังก์ชัน A จะเป็น Dominant ก็ต่อเมื่อ คะแนนของ A มากกว่าหรือเท่ากับคะแนนของทุกๆ ฟังก์ชัน (f)")

        st.markdown("---")

        st.markdown("### 3. ตรรกศาสตร์การเลือก Auxiliary (ฟังก์ชันรอง)")
        st.markdown("**กรณีที่ Dom = Ne:**")
        st.latex(r"(\text{Dom} = Ne) \implies (\text{Aux} \in \{Ti, Fi\})")
        st.write("* **เงื่อนไขที่ 1:** ถ้า `Score(Ti) > Score(Fi)` แล้ว `(Aux = Ti ∧ Type = ENTP)`")
        st.write("* **เงื่อนไขที่ 2:** ถ้า `Score(Fi) > Score(Ti)` แล้ว `(Aux = Fi ∧ Type = ENFP)`")

        st.markdown("---")

        st.markdown("### 4. กฎคู่สมดุลตรงข้าม (สมมูลทางตรรกศาสตร์ ⇔)")
        st.latex(r"\text{Dom} = Ne \iff \text{Inferior} = Si")
        st.latex(r"\text{Aux} = Ti \iff \text{Tertiary} = Fe")
        st.latex(r"\text{Aux} = Fi \iff \text{Tertiary} = Te")

    # ---------------------------------------------------------
    # ปุ่มกดเปลี่ยนหน้า
    # ---------------------------------------------------------
    st.markdown("---")
    col1, col2 = st.columns(2)
    with col1:
        if st.button("⬅ ทำแบบประเมิน MBTI ใหม่"):
            st.session_state.step = 1
            st.rerun()
    with col2:
        if st.button("➡️ ไปต่อ: ประเมินความชอบ & ทุนการเงิน (Step 3)"):
            st.session_state.step = 3
            st.rerun()

# ---------------------------------------------------------
# STEP 3: ประเมินความชอบ วิชา งานอดิเรก เป้าหมาย ทุนการเงิน
# ---------------------------------------------------------
elif st.session_state.step == 3:
    st.title("🎯 ขั้นตอนที่ 3: ระบุวิชาที่ชอบ งานอดิเรก เป้าหมาย และทุนการเงิน")
    st.write("ส่วนนี้จะนำความชอบจริงของคุณไปผสมผสานกับ MBTI เพื่อให้อาชีพเจาะจงและตรงใจมากที่สุด")
    
    with st.form("preference_form"):
        st.subheader("📚 1. ความชอบหมวดวิชาการ")
        sub_scores = {}
        for q in SUBJECT_QUESTIONS:
            ans = st.radio(f"{q['text']} ({q['category']}):", options=list(SCALE_OPTIONS.keys()), index=2, key=f"sub_{q['id']}", horizontal=True)
            sub_scores[q["category"]] = sub_scores.get(q["category"], 0) + SCALE_OPTIONS[ans]
            
        st.markdown("---")
        st.subheader("🎨 2. ความสนใจและงานอดิเรก")
        hob_scores = {}
        for q in HOBBY_QUESTIONS:
            ans = st.radio(f"{q['text']} ({q['category']}):", options=list(SCALE_OPTIONS.keys()), index=2, key=f"hob_{q['id']}", horizontal=True)
            hob_scores[q["category"]] = hob_scores.get(q["category"], 0) + SCALE_OPTIONS[ans]
            
        st.markdown("---")
        st.subheader("🎯 3. สไตล์และเป้าหมายการทำงาน")
        goal_scores = {}
        for q in GOAL_QUESTIONS:
            ans = st.radio(f"{q['text']} ({q['category']}):", options=list(SCALE_OPTIONS.keys()), index=2, key=f"goal_{q['id']}", horizontal=True)
            goal_scores[q["category"]] = goal_scores.get(q["category"], 0) + SCALE_OPTIONS[ans]

        st.markdown("---")
        st.subheader("💰 4. เงื่อนไขและงบประมาณการศึกษา")
        fin_answers = {}
        for q in FINANCIAL_QUESTIONS:
            ans = st.selectbox(q["label"], options=q["options"], key=f"fin_{q['id']}")
            fin_answers[q["id"]] = ans

        submitted_step3 = st.form_submit_button("🚀 ประมวลผลสรุปเส้นทางอนาคต (Step 4)")
        
        if submitted_step3:
            top_subject = max(sub_scores, key=sub_scores.get)
            top_hobby = max(hob_scores, key=hob_scores.get)
            
            st.session_state.subject_scores = sub_scores
            st.session_state.user_preferences = {
                "top_subject": top_subject,
                "top_hobby": top_hobby,
                "financial": fin_answers
            }
            st.session_state.step = 4
            st.rerun()

# ---------------------------------------------------------
# STEP 4: สรุปผลลัพธ์อาชีพและสถาบันการศึกษา
# ---------------------------------------------------------
elif st.session_state.step == 4:
    st.balloons()
    st.title("🎓 ขั้นตอนที่ 4: สรุปผลลัพธ์อาชีพและสถาบันการศึกษาที่ใช่สำหรับคุณ")
    
    mbti = st.session_state.mbti_result
    prefs = st.session_state.user_preferences
    top_subject = prefs.get("top_subject", "Math & Logic")
    top_hobby = prefs.get("top_hobby", "Tech & Gaming")
    fin = prefs.get("financial", {})

    budget_ans = fin.get("fin_budget", "")
    scholar_ans = fin.get("fin_scholarship_need", "")

    st.markdown(f"""
    <div style="background-color: #F0F9FF; border: 1px solid #BAE6FD; padding: 1.2rem; border-radius: 10px; margin-bottom: 1.5rem;">
        <b>👤 โปรไฟล์สรุปของคุณ:</b><br>
        • MBTI: <b>{mbti}</b><br>
        • วิชาที่โดดเด่นที่สุด: <b>{top_subject}</b><br>
        • หมวดงานอดิเรกที่ใช่: <b>{top_hobby}</b><br>
        • เงื่อนไขการเงิน: <b>{budget_ans}</b>
    </div>
    """, unsafe_allow_html=True)

    st.subheader("💼 เส้นทางอาชีพแนะนำ (ผสมผสาน MBTI × วิชาที่ชอบ)")
    
    career_list = []
    if top_subject in ["Natural Science", "วิทยาศาสตร์/เคมี/ชีวา"] or top_hobby == "Hands-on":
        career_list = [
            {"title": f"บุคลากรทางการแพทย์ / นักวิจัยสุขภาพ (สไตล์ {mbti})", "desc": "เหมาะกับผู้ที่สนใจสายสุขภาพ นำจุดเด่นทางนิสัยมาประยุกต์กับการดูแลผู้ป่วยหรือการวิจัย"},
            {"title": "นักวิชาการสาธารณสุข / นักชีววิทยาประยุกต์", "desc": "เน้นการวิเคราะห์ข้อมูลทางวิทยาศาสตร์และการพัฒนาสุขภาวะในระดับโครงสร้าง"}
        ]
    elif top_subject in ["Technology", "Math & Logic", "คอมพิวเตอร์/เทคโนโลยี", "คณิตศาสตร์/ฟิสิกส์"] or top_hobby == "Tech & Gaming":
        career_list = [
            {"title": f"Software Engineer / Data Scientist (สไตล์ {mbti})", "desc": "นำตรรกะและการวิเคราะห์เชิงระบบมาสร้างสรรค์เทคโนโลยีและแก้ปัญหาซับซ้อน"},
            {"title": "นักออกแบบระบบไอที / Cybersecurity Specialist", "desc": "ใช้วิธีคิดเชิงโครงสร้างเพื่อวางระบบความปลอดภัยและเทคโนโลยีแห่งอนาคต"}
        ]
    elif top_subject in ["Art & Design", "ศิลปะ/ออกแบบ"] or top_hobby == "Creative":
        career_list = [
            {"title": f"UX/UI Designer / Creative Director (สไตล์ {mbti})", "desc": "ผสมผสานศิลปะ ความเข้าใจมนุษย์ และเทคโนโลยีเข้าด้วยกันเพื่อสร้างประสบการณ์ผู้ใช้"},
            {"title": "นักจัดทำคอนเทนต์ / สื่อมวลชนดิจิทัล", "desc": "สื่อสารเรื่องราวและสร้างแรงบันดาลใจผ่านสื่อหลากหลายรูปแบบ"}
        ]
    else:
        career_list = [
            {"title": f"นักวางแผนกลยุทธ์ / นักการตลาด (สไตล์ {mbti})", "desc": "บริหารจัดการ บริหารคน และวางแผนเพื่อให้บรรลุเป้าหมายองค์กร"},
            {"title": "นักการทูต / นักวิเคราะห์นโยบายสังคม", "desc": "ใช้วาทศิลป์และความเข้าใจพฤติกรรมมนุษย์ในการสร้างความร่วมมือ"}
        ]

    col_c1, col_c2 = st.columns(2)
    for idx, c in enumerate(career_list):
        with (col_c1 if idx % 2 == 0 else col_c2):
            st.markdown(f"""
            <div style="background-color: white; border: 2px solid #3B82F6; padding: 1.2rem; border-radius: 12px; margin-bottom: 1rem;">
                <h4 style="color: #1E3A8A; margin-top:0;">{c['title']}</h4>
                <p style="color: #475569;">{c['desc']}</p>
            </div>
            """, unsafe_allow_html=True)

    st.subheader("🏛️ สถาบันการศึกษาและทุนการศึกษาที่แนะนำ")
    
    if "จำกัดสูง" in budget_ans or "สนใจมาก" in scholar_ans:
        st.success("""
        **🎓 แนะนำสถาบันทุนเรียนฟรี / มีเบี้ยเลี้ยง / มีประกันงานทำ 100%:**
        - **สถาบันพระบรมราชชนก / วิทยาลัยพยาบาลบรมราชชนนี:** ทุนเรียนฟรี มีเบี้ยเลี้ยง จบแล้วบรรจุเป็นข้าราชการทันที
        - **วิทยาลัยพยาบาลเหล่าทัพ (ทหารบก / ทหารเรือ / ทหารอากาศ / ตำรวจ):** ทุนเต็มจำนวนพร้อมสวัสดิการ บรรจุเป็นนายทหาร/ตำรวจ
        - **ทุนครูคืนถิ่น / ทุนผลิตครูเพื่อพัฒนาท้องถิ่น:** ทุนการศึกษาพร้อมการันตีบรรจุตำแหน่งครูในภูมิลำเนา
        - **ทุน กยศ. / กรอ.:** สนับสนุนค่าเล่าเรียนสำหรับสถาบันรัฐและเอกชนที่เข้าร่วม
        """)
    elif "ปานกลาง" in budget_ans:
        st.info("""
        **🏛️ แนะนำมหาวิทยาลัยรัฐบาลหลัก (ค่าเทอมตามมาตรฐาน):**
        - **สายสุขภาพ/วิทยาศาสตร์:** มหาวิทยาลัยมหิดล, จุฬาลงกรณ์มหาวิทยาลัย, มหาวิทยาลัยเชียงใหม่
        - **สายเทคโนโลยี/วิศวะ:** กลุ่ม 3 พระจอมเกล้า (สจล., มจธ., มจพ.), มหาวิทยาลัยเกษตรศาสตร์
        - **สายสังคม/บริหาร/ศิลปะ:** มหาวิทยาลัยธรรมศาสตร์, มหาวิทยาลัยศิลปากร, มศว
        """)
    else:
        st.warning("""
        **🌟 แนะนำสถาบันเอกชนชั้นนำ / หลักสูตรนานาชาติ:**
        - **มหาวิทยาลัยเอกชน:** มหาวิทยาลัยกรุงเทพ, มหาวิทยาลัยรังสิต, มหาวิทยาลัยศรีปทุม, มหาวิทยาลัยอัสสัมชัญ (ABAC)
        - **หลักสูตรนานาชาติมหาลัยรัฐ:** SIIT มหาวิทยาลัยธรรมศาสตร์, ICT มหาวิทยาลัยมหิดล, ISE จุฬาลงกรณ์มหาวิทยาลัย
        """)

    st.markdown("---")
    if st.button("🔄 เริ่มทำแบบประเมินใหม่อีกครั้ง"):
        st.session_state.step = 1
        st.session_state.user_preferences = {}
        st.rerun()
