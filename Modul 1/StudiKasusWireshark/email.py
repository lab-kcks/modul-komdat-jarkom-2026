import smtplib
from email.mime.text import MIMEText

msg = MIMEText("Menurutku tomboy lebih baik daripada femboy.")
msg["Subject"] = "whnyh"
msg["From"] = "pengirim@lab.local"
msg["To"] = "penerima@lab.local"

with smtplib.SMTP("localhost", 1025) as server:
    server.send_message(msg)