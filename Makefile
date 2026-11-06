# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: vgoret                                     +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/11/02                               #+#    #+#              #
#    Last updated:                                    ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

CLUSTER = iot-part3

all: install cluster namespacces argocd app

install:
	./scripts/setup.sh

cluster:
	k3d cluster create ${CLUSTER}

namespaces:
	kubectl apply -f confs/namespaces.yaml

argocd:
	kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl wait --for=condition=available deploy/argocd-server -n argocd --timeout=300s

app: 
	kubectl apply -f confs/application.yaml

clean:
	k3d cluster delete ${CLUSTER}

PURPLE		=	\033[1;35m
RESET		= 	\033[0m
banner : 
	@echo "${PURPLE}▘        ▗ ▘        ▐▘  ▗ ▌ ▘         ▌    ▄▖"
	@echo "${PURPLE}▌▛▌▛▘█▌▛▌▜▘▌▛▌▛▌▄▖▛▌▜▘▄▖▜▘▛▌▌▛▌▛▌▛▘  ▐   ▛▌▄▌"
	@echo "${PURPLE}▌▌▌▙▖▙▖▙▌▐▖▌▙▌▌▌  ▙▌▐   ▐▖▌▌▌▌▌▙▌▄▌  ▞   ▙▌▄▌"
	@echo "${PURPLE}       ▌                       ▄▌    ▘   ▌\n${RST}"

.PHONY : all clean fclean all re
