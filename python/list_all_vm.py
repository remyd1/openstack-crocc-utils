import openstack
# faire du profiling
import argparse
import cProfile
import pstats
import io


# Connexion à OpenStack en tant qu'administrateur
conn = openstack.connect()

def list_all_instances(conn, detailed=False, host=False):
    if detailed:
        for server in conn.compute.servers(all_projects=True, details=True):
            project = conn.identity.get_project(server.project_id)
            if host:
                print(f"Instance ID: {server.id}, Name: {server.name}, "
                  f"Project: {project.name}, Status: {server.status}, "
                  f"Host: {getattr(server, 'OS-EXT-SRV-ATTR:host', 'N/A')}")
            else:
                print(f"Instance ID: {server.id}, Name: {server.name}, "
                  f"Project: {project.name}, Status: {server.status}, ")
    else:
        for server in conn.compute.servers(all_projects=True, details=False):
            #print(server)
            print(f"Instance: {server.name}, ID: {server.id}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--detailed', action='store_true',
                        help='Affiche des informations détaillées sur chaque instance')
    parser.add_argument('--profile', action='store_true',
                        help='Active le profiling')
    parser.add_argument('--host', action='store_true',
                        help='Affiche le host')
    args = parser.parse_args()
    if args.profile:
        pr = cProfile.Profile()
        pr.enable()
    conn = openstack.connect()

    list_all_instances(conn, detailed=args.detailed, host=args.host)
    if args.profile:
        pr.disable()
        s = io.StringIO()
        sortby = 'cumulative'
        ps = pstats.Stats(pr, stream=s).sort_stats(sortby)
        ps.print_stats()
        print(s.getvalue())


if __name__ == "__main__":
    main()