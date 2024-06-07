package main

import (
	"flag"
	"fmt"
	"log"

	"github.com/gophercloud/gophercloud/openstack/compute/v2/servers"
	"github.com/gophercloud/gophercloud/pagination"
	"github.com/gophercloud/utils/openstack/clientconfig"
)

func main() {
	var err error
	// Définition de l'option --detail
	detailed := flag.Bool("detail", false, "Affiche des informations détaillées sur chaque instance")
	flag.Parse()

	// Authentification
	opts := new(clientconfig.ClientOpts)
	client, err := clientconfig.NewServiceClient("compute", opts)
	if err != nil {
		log.Fatalf("Erreur lors de la création du client Compute : %v", err)
		return
	}

	var pager pagination.Page
	if *detailed {
		pager, err = servers.List(client, servers.ListOpts{AllTenants: true}).AllPages()
	} else {
		pager, err = servers.ListSimple(client, servers.ListOpts{AllTenants: true}).AllPages()
	}
	if err != nil {
		fmt.Println(err)
		return
	}

	servers, err := servers.ExtractServers(pager)
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println("servers:")
	for _, server := range servers {
		if *detailed {
			fmt.Printf("Project ID: %s, Instance ID: %s, Host ID: %s, Status: %s, Name: %s\n", server.TenantID, server.ID, server.HostID, server.Status, server.Name)
		} else {
			fmt.Printf("Instance ID: %s, Name: %s\n", server.ID, server.Name)
		}
	}

}
