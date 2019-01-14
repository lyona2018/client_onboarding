import configparser
import logging
import multiprocessing as mp
import os.path
import pymysql
import smtplib
import sys
from datetime import datetime as datetime
from email import encoders
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText


# Lucky Yona, Winter 2018.
# Script is intended to call non competing MySQL stored procedures at the same time, achieving some parrallel processing and saving time
# Next step is to do the same for the data loading.


def get_mysql_connection(host, port, user, password, db):
    try:
        connection = pymysql.connect(host=host,
                                     port=port,
                                     user=user,
                                     password=password,
                                     db=db,
                                     charset='utf8mb4',
                                     autocommit=True)

        return connection
    except pymysql.err.OperationalError as e:
        print(str(e), file=sys.stderr)
        logging.error(str(e))
        return


def log_sender(recipient, subject):
    email = 'info@tradeinformatics.com'
    password = 'password'
    send_to_email = 'lyona@tradeinformatics.com'
    subject = str(subject)
    message = 'Kindly find logs attached'
    log_filename = "Bluecrest--{}.log".format(datetime.now().strftime("%Y%m%d-%H%M"))
    file_location = '/home/clob_admin/client_onboarding/bluecrest/logs/{}'.format(log_filename)

    msg = MIMEMultipart()
    msg['From'] = email
    msg['To'] = send_to_email
    msg['Subject'] = subject

    msg.attach(MIMEText(message, 'plain'))

    filename = os.path.basename(file_location)
    attachment = open(file_location, "rb")
    part = MIMEBase('application', 'octet-stream')
    part.set_payload((attachment).read())
    encoders.encode_base64(part)
    part.add_header('Content-Disposition', "attachment; filename= %s" % filename)

    msg.attach(part)

    server = smtplib.SMTP()
    server.connect()
    text = msg.as_string()
    server.sendmail(email)


# define a example function
def routines(region, processDate_in, return_dict):
    #  region process database connection detail
    logging.info("Started processing {}".format(region, ))
    reader = configparser.RawConfigParser()
    reader.read('/home/clob_admin/client_onboarding/bluecrest/conf/mysql.cnf')
    host = reader.get('bluecrest', 'host')
    user = reader.get('bluecrest', 'user')
    port = reader.get('bluecrest', 'port')
    password = reader.get('bluecrest', 'password')
    db = reader.get('bluecrest', 'db')

    connection = get_mysql_connection(host, int(port), user, password, db)

    if connection is None:
        return_dict[region] = 1
        return 1
        sys.exit(1)

    try:
        with connection.cursor() as cursor:
            cursor.execute('call process_routine_{}({});'.format(region, processDate_in))
            logging.info("Procedure succeeded for region {}".format(region, ))


    except Exception as error:
        hup = randint(300, 500)
        logging.error("{} failed.".format(region, hup))
        return_dict[region] = error.args[0]
        return error.args[0]

    finally:
        connection.close()

    return_dict[region] = 0
    return 0


def main():
    if len(sys.argv) < 2:
        print('Too few arguments, please specify a process date and email recipient in that order')
        sys.exit(1)

    processDate_in = sys.argv[1]
    recipient = sys.argv[2]

    logFile = datetime.now().strftime("/home/clob_admin/client_onboarding/bluecrest/logs/bluecrest_%Y%m%d.log")
    logging.basicConfig(filename=logFile, filemode='a',
                        format='%(asctime)s-%(process)d-%(levelname)s-%(filename)s:%(lineno)s-%(message)s',
                        level=logging.INFO)
    logging.info("START")

    # pdb.set_trace()

    tasks = ['EMEA', 'AMER', 'APAC']
    procs = []

    manager = mp.Manager()
    return_dict = manager.dict()

    for task in tasks:
        proc = mp.Process(target=routines, args=(task, processDate_in, return_dict))
        procs.append(proc)
        proc.start()

    for proc in procs:
        proc.join()

    print(return_dict)


if __name__ == '__main__':
    main()
