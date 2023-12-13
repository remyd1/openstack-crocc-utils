package main

import (
	"flag"
	"fmt"
	"log"

	"github.com/gophercloud/gophercloud"
	"github.com/gophercloud/gophercloud/openstack/identity/v3/projects"
	"github.com/gophercloud/gophercloud/openstack/networking/v2/extensions/layer3/routers"
	"github.com/gophercloud/gophercloud/openstack/networking/v2/ports"
	"github.com/gophercloud/gophercloud/pagination"
	"github.com/gophercloud/utils/openstack/clientconfig"
)

func projectExists(client *gophercloud.ServiceClient, projectID string) bool {
	_, err := projects.Get(client, projectID).Extract()
	return err == nil
}

func listAttachedPorts(networkClient *gophercloud.ServiceClient, routerID string, delete bool) {
	listOpts := ports.ListOpts{
		DeviceID: routerID,
	}

	ports.List(networkClient, listOpts).EachPage(func(page pagination.Page) (bool, error) {
		portList, err := ports.ExtractPorts(page)
		if err != nil {
			return false, err
		}
		for _, port := range portList {
			fmt.Printf("Port ID: %s ", port.ID)
			if delete {
				// suppression du port du routeur
				fmt.Printf("Suppression du port %s\n", port.ID)
				intOpts := routers.RemoveInterfaceOpts{
					PortID: port.ID,
				}
				_, err := routers.RemoveInterface(networkClient, routerID, intOpts).Extract()
				if err != nil {
					fmt.Printf("Erreur lors de la suppression du port %s : %v\n", port.ID, err)
				}
			}
		}

		return true, nil
	})
}

func main() {
	var err error
	delete := flag.Bool("delete", false, "Affiche des informations détaillées sur chaque instance")
	debug := flag.Bool("debug", false, "Affiche des informations détaillées sur chaque instance")
	flag.Parse()
	// Authentification
	// Authentification
	opts := new(clientconfig.ClientOpts)
	networkClient, err := clientconfig.NewServiceClient("network", opts)
	identityClient, err := clientconfig.NewServiceClient("identity", opts)
	if err != nil {
		log.Fatalf("Erreur lors de la création du client Compute : %v", err)
		return
	}

	// Lister tous les routeurs
	err = routers.List(networkClient, routers.ListOpts{}).EachPage(func(page pagination.Page) (bool, error) {
		routerList, err := routers.ExtractRouters(page)
		if err != nil {
			return false, err
		}

		for _, router := range routerList {
			if *debug {
				fmt.Printf("Routeur ID: %s, Nom: %s, Project ID: %s\n", router.ID, router.Name, router.TenantID)
			}
			// Vérifier si le projet existe
			if !projectExists(identityClient, router.TenantID) {
				fmt.Printf("Le projet %s n'existe pas pour le router %s...\n", router.TenantID, router.ID)
				listAttachedPorts(networkClient, router.ID, *delete)
				if *delete {
					fmt.Printf("Suppression du routeur %s\n", router.ID)
					err = routers.Delete(networkClient, router.ID).ExtractErr()
					if err != nil {
						fmt.Printf("Erreur lors de la suppression du routeur %s : %v\n", router.ID, err)
					}
				}
			}
		}

		return true, nil
	})

	if err != nil {
		log.Fatalf("Erreur lors de la récupération des routeurs : %v", err)
	}
}
