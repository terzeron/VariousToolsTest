#include <it.h>
#ifdef IT_WINDOWS
#include <strstrea.h>
#else
#include <strstream.h>
#endif

char *token;

int usage();
ITCallbackResult my_error_handler(const ITErrorManager &errorobject, void *userdata, long errorlevel)
{
	ostream *stream = (ostream *) userdata;
	if (errorlevel == 0)
		(*stream) << "Change in transaction state." << endl;
	else {
		(*stream) << "Error level = " << errorlevel << "\n" << (errorobject.Warn() == TRUE ? "Warning: " : "Error: ") << "SQLSTATE = " << errorobject.SqlState() << "\n" << (errorobject .Warn() == TRUE ? errorobject.WarningText() : errorobject.ErrorText()) << endl;
	}

	return IT_HANDLED;
}

int main(int argc, char **argv)
{
	char dbname[19] = "ius02";
	char server[19];
	ITDBInfo dbinfo;
	ITConnection conn;
	char qtext[1024];
	ITSystemNameList list;
	ITString sys_name;
	BOOL selected = FALSE;

	if (argc > 2) {
		usage();
		exit(-1);
	} else if (argc == 2) {
		strcpy(server, argv[1]);
		selected = TRUE;
	}

	if (selected == FALSE) {
		list.AddCallback(my_error_handler, (void *) &cerr);
		ITBool created = list.Create();
		cout << "Server list are ..." << endl;
		if (created) {
			while (ITString::Null != (sys_name = list.NextSystemName()))
				cout << sys_name << endl;
		}	
		cout << "Which server do you want ? " << endl;
		gets(server);
	}

	cout << "Server name is " << server;
	dbinfo.SetSystem(server);
	dbinfo.SetDatabase(dbname);

	/* Open Connection */
	conn.AddCallback(my_error_handler, (void *) &cerr);	
	conn.Open(dbinfo);
	ITQuery query(conn);

	cout << "Enter your query: " << endl;
	gets(qtext);

	if (query.ExecForIteration(qtext)) {
		ITRow *row;
		while ((row = query.NextRow()) != NULL) {
			cout << row->Printable() << endl;
			row->Release;
		}
		cout << endl;
	}
	return 0;
}

int usage()
{
	cerr << "USAGE: " << "creatdb database_name" << endl;
	cerr << "        or" << endl;
	cerr << "       creatdb database_name@server" << endl;
	return -1;
}