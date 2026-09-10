import smtplib
from email.mime.text import MIMEText

msg = MIMEText("Menurutku tomboy lebih baik daripada femboy.")
msg["Subject"] = "whnyh"
msg["From"] = "pengirim@lab.local"
msg["To"] = "penerima@lab.local"

with smtplib.SMTP("127.0.0.1", 25) as server:
    server.send_message(msg)