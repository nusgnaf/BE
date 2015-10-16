import vibe.vibe, std.file, std.getopt, std.path, std.process, std.stdio;


// basic RESTful stuff! 
@path("/api")
interface IMyAPI
{
    // GET /api/greeting
    @property string greeting();

    // PUT /api/greeting
    @property void greeting(string text);

    // POST /api/users
    @path("/users")
    void addNewUser(string name);

    // GET /api/users
    @property string[] users();

    // GET /api/:id/name
    string getName(int id);

    // GET /some_custom_json
    Json getSomeCustomJson();
}

// vibe.d takes care of all JSON encoding/decoding
// and actual API implementation can work directly
// with native types

class API : IMyAPI
{
    private {
        string m_greeting;
        string[] m_users;
    }

    @property string greeting() { return m_greeting; }
    @property void greeting(string text) { m_greeting = text; }

    void addNewUser(string name) { m_users ~= name; }

    @property string[] users() { return m_users; }

    string getName(int id) { return m_users[id]; }

    Json getSomeCustomJson()
    {
        Json ret = Json.emptyObject;
        ret["somefield"] = "Hello, World!";
        return ret;
    }
}
int main()
{
    scope settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["127.0.0.1"];
    //bool help;
    auto router = new URLRouter;
    // add Rest stuff
    router.registerRestInterface(new API());


    readOption("bind|b", &settings.bindAddresses[0],
        "Sets the address used for serving. (default 127.0.0.1)");
    readOption("port|p", &settings.port, "Sets the port used for serving. (default 8080)");

    // returns false if a help screen has been requested and displayed (--help)
    string[] args;
    if (!finalizeCommandLineOptions(&args))
        return 0;

    auto path = args.length > 1 ? args[1] : ".";

    if (path.isDir)
    {
        writefln("serving '%s'", path);
        router.get("*", serveStaticFiles(path));
        listenHTTP(settings, router);
    }
    else
    {
        path = path.absolutePath.buildNormalizedPath;
        auto folder = path.dirName;
        writefln("serving '%s'", folder.relativePath);
        router.get("*", serveStaticFiles(folder));
        listenHTTP(settings, router);

        if (path.extension == ".html")
        {
            auto url = URL("http", settings.bindAddresses[0], settings.port,
                Path(path.chompPrefix(folder)));
            writefln("opening %s in a browser", url);
            browse(url.toString());
        }
    }

    lowerPrivileges();
    return runEventLoop();
}
