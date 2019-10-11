#include <it.h>
#ifdef IT_WINDOWS
#include <strstrea.h>
#else
#include <strstream.h>
#endif

char *token;

int usage();

int main(int argc, char **argv)
{
	char dbname[19];
	char server[19];
	ITDBInfo dbinfo;

	if (argc != 2) {
		usage();
		return -1;
	}

	token = strtok(argv[1], "@");
	strcpy(dbname, token);

	dbinfo.SetDatabase(dbname);
	token = strtok(NULL, "@");
	if (token != NULL) {
		strcpy(server, token);
		dbinfo.SetSystem(server);
	}

	ITBool retval = dbinfo.CreateDatabase(ITDBInfo::BufferedLog, "dbs");

	if (retval)
		cout << "Successfully created " << argv[1] << endl;
	else
		cout <<  "Attempt to create " << argv[1] << " failed." << endl;
	return (retval?0:-1);
}

int usage()
{
	cerr << "USAGE: " << "creatdb database_name" << endl;
	cerr << "        or" << endl;
	cerr << "       creatdb database_name@server" << endl;
	return -1;
}