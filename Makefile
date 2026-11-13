# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: vgoret                                     +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/11/02                               #+#    #+#              #
#    		                                      ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

CLUSTER = iot-part3

all: banner install cluster namespaces argocd app

install:
	./scripts/setup.sh

cluster:
	@if k3d cluster list ${CLUSTER} >/dev/null 2>&1; then \
		echo "Cluster ${CLUSTER} already exists, making sure it is running"; \
		k3d cluster start ${CLUSTER}; \
	else \
		k3d cluster create ${CLUSTER}; \
	fi
	kubectl config use-context k3d-${CLUSTER}

namespaces:
	kubectl apply -f confs/namespaces.yaml

argocd:
	kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl wait --for=condition=available deploy --all -n argocd --timeout=300s

app: 
	kubectl apply -f confs/application.yaml

password:
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo ;

forward-argocd: password
	kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0

forward-app:
	  while true; do kubectl port-forward svc/service-planet-visualizer -n dev 8888:8888 --address 0.0.0.0; sleep 1; done

clean:
	k3d cluster delete ${CLUSTER}

re: clean all

PURPLE		=	\033[1;35m
RESET		= 	\033[0m
banner: 
	@echo "${PURPLE}▘        ▗ ▘        ▐▘  ▗ ▌ ▘         ▌    ▄▖${RST}"
	@echo "${PURPLE}▌▛▌▛▘█▌▛▌▜▘▌▛▌▛▌▄▖▛▌▜▘▄▖▜▘▛▌▌▛▌▛▌▛▘  ▐   ▛▌▄▌${RST}"
	@echo "${PURPLE}▌▌▌▙▖▙▖▙▌▐▖▌▙▌▌▌  ▙▌▐   ▐▖▌▌▌▌▌▙▌▄▌  ▞   ▙▌▄▌${RST}"
	@echo "${PURPLE}       ▌                       ▄▌    ▘   ▌\n${RST}"

.PHONY : all clean re install cluster namespaces argocd app password ui clean re banner
