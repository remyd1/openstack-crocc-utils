import openstack
import sys

# Connexion à OpenStack
conn = openstack.connect()

# verification si de vm fonctionne
def check_vm(conn, project_id):
    print(f"Vérification si des ressources Nova sont présentes pour le projet {project_id}")
    # pour chaque VM dans le projet
    found_vm = False
    for vm in conn.compute.servers(all_tenants=True, project_id=project_id):
      print(f"VM trouvée : {vm.id}")
      if vm.id is not None:
        print(f"Au moins une VM : {vm.id}")
        found_vm = True
    
    if found_vm:
      return True
    else:
      print("Aucune VM trouvée.")
      return False
            
# Fonction pour purger les ressources Neutron
def purge_neutron_resources(conn, project_id, dry_run=False):
    print(f"{'Simulation de' if dry_run else 'Début de'} la purge des ressources Neutron pour le projet {project_id}")
    # Supprimer les ports
    for port in conn.network.ports(project_id=project_id):
        print(f"Suppression du port : {port.id}")
        if port.device_owner == 'network:router_interface':
            print(f"Détachement de l'interface {port.id} du routeur {port.device_id}")
            try:
              if not dry_run:
                conn.network.remove_interface_from_router(port.device_id, None, port.id)
            except Exception as e:
              if not dry_run: 
                print(f"Erreur lors du détachement de l'interface {port.id} du routeur {port.device_id}")
                print(e)
                conn.network.remove_gateway_from_router(port.device_id)
        if not dry_run:
            conn.network.delete_port(port)
    # Supprimer les routeurs
    for router in conn.network.routers(project_id=project_id):
        # pour chaque interface du routeur, la détacher du routeur
        for port in conn.network.ports(device_id=router.id):
            if port.device_owner.startswith('network:router_interface'):
                print(f"Détachement de l'interface {port.id} du routeur {router.id}")
                if not dry_run:
                    conn.network.remove_interface_from_router(router, {'port_id': port.id})
        print(f"Suppression du routeur : {router.id}")
        if not dry_run:
            conn.network.delete_router(router)

    # Supprimer les sous-réseaux
    for subnet in conn.network.subnets(project_id=project_id):
        print(f"Suppression du sous-réseau : {subnet.id}")
        if not dry_run:
            conn.network.delete_subnet(subnet)

    # Supprimer les réseaux
    for network in conn.network.networks(project_id=project_id):
        print(f"Suppression du réseau : {network.id}")
        if not dry_run:
           conn.network.delete_network(network)
    # Supprimer les floating ips
    for floating_ip in conn.network.ips(floating_ip_address=None, project_id=project_id):
        print(f"Suppression de la floating ip : {floating_ip.id}")
        if not dry_run:
            conn.network.delete_ip(floating_ip)
    if dry_run:
        print("Fin de la simulation.")
    else:
        print("Purge des ressources Neutron terminée.")

# Analyser les arguments de la ligne de commande
if len(sys.argv) < 2:
    print("Usage: python script.py PROJECT_ID [dry-run]")
    sys.exit(1)

project_id = sys.argv[1]
dry_run = len(sys.argv) > 2 and sys.argv[2] == 'dry-run'

if(check_vm(conn, project_id)):
    print("Des VMs sont présentes dans le projet, la purge des ressources Neutron ne peut pas être effectuée.")
    sys.exit(1)

# Appeler la fonction avec l'ID du projet et l'option dry-run si spécifiée
purge_neutron_resources(conn, project_id, dry_run=dry_run)
