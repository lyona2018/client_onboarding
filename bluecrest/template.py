#!/usr/bin/python3

import configparser
import logging
import pymysql.cursors
import signal
import subprocess
import sys
import time
import traceback
from datetime import datetime
from multiprocessing import Process
from socket import gethostname


def signal_handler(signal, frame):
    print("\njobber exiting gracefully")
    logging.info("Exiting gracefully")
    sys.exit(0)


def run_slammer(request_id, client_code, start_date, end_date, PM, DESK, BROKER, VENUE, start_date_use_dc,
                end_date_use_dc, query_filter):
    try:
        print("run slammer called for {}\n".format(request_id))

        logging.info(f"RUN SLAMMER FUNCTION CALLED FOR {request_id}\n")

        start_date = start_date.strftime("%Y-%m-%d")
        end_date = end_date.strftime("%Y-%m-%d")

        '''
        request_id = args[0]
        client_code = args[1]
        start_date = args[2].strftime("%Y-%m-%d")
        end_date = args[3].strftime("%Y-%m-%d")
        PM = args[4]
        DESK = args[5]
        BROKER = args[6]
        VENUE = args[7]
        start_date_use_dc = args[8]
        end_date_use_dc = args[9]
        query_filter = args[10]
        '''
        cmd = "./slammer.py -c{0} -s{1} -e{2} -r{3} 2>&1".format(client_code, start_date, end_date, request_id)

        print("calling {}\n".format(cmd))

        logging.info("TRIGGER SUBPROCESS {}\n".format(cmd))

        return_code = subprocess.check_call(cmd, shell=True)

        logging.info("DONE WITH SUBPROCESS {}\n".format(cmd))
        logging.info("RETURN_CODE = {}".format(return_code))

        print("done with: {}\n".format(cmd))
        print ("return_code = {}\n".format(return_code))

        return return_code

    except Exception:
        traceback.print_exc()


def get_mysql_connection(host, port, user, password, db):
    try:
        connection = pymysql.connect(host=host,
                                     port=port,
                                     user=user,
                                     password=password,
                                     db=db,
                                     charset='utf8mb4', autocommit=True)

        return connection
    except pymysql.err.OperationalError as e:
        print(str(e), file=sys.stderr)
        return


def main(argv):
    try:
        # pdb.set_trace()
        print("START")
        logFile = datetime.now().strftime('log/jobber_%Y%m%d.log')
        logging.basicConfig(filename=logFile, filemode='a', format='%(asctime)s-%(process)d-%(levelname)s-%(message)s',
                            level=logging.INFO)

        host_name = gethostname()
        logging.info("START - HOST {}".format(host_name))

        signal.signal(signal.SIGINT, signal_handler)

        #  region process database connection detail

        reader = configparser.RawConfigParser()
        reader.read('jobber.cnf')
        host = reader.get('poc', 'host')
        user = reader.get('poc', 'user')
        port = reader.get('poc', 'port')
        password = reader.get('poc', 'password')

        connection = get_mysql_connection(host, int(port), user, password, 'poc')

        if connection is None:
            sys.exit(3)

        #  endregion

        try:
            while True:

                print("Check if there is anything to execute\n")

                #  region determine tap requests to execute next, mark them started and trigger them to run
                sql = "select pivot_id, client_code, start_date, end_date, PM, DESK, BROKER, VENUE, start_date_use_dc, end_date_use_dc, filter " + \
                      "from tap_request where status = 'NEW' and client_code = 'BLUECREST' and pivot_id > 18 order by time_requested;"

                data = None
                # pdb.set_trace()
                with connection.cursor() as cursor:
                    cursor.execute(sql)
                    data = list(cursor.fetchall())
                    print("Data: {}".format(data))

                if data is not None and len(data) != 0:

                    for row in data:
                        print(row)
                        print("\n")
                        status_sql = "update tap_request set status = 'START' where pivot_id = {}".format(row[0])

                        with connection.cursor() as cursor:
                            cursor.execute(status_sql)

                        connection.commit()

                        logging.info("TRIGGER {} \n".format(row[0]))

                        p = Process(target=run_slammer, args=row)
                        p.start()

                #  endregion
                print("Sleep 3 seconds\n")
                time.sleep(3)


        except Exception:
            traceback.print_exc()
        finally:
            connection.close()

    except Exception:
        traceback.print_exc()


if __name__ == "__main__":
    main(sys.argv)
