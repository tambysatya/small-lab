
source scripts/utils.sh

generate_plain_hex(){
	# Generates a plain text secret of a given size
	# Do nothing if the secret already exists
	
	local SECRET_FILENAME=$1
	local SIZE=$2

	local TARGET_DIR="secrets/plain/tokens"
	local SECRET_PATH="$TARGET_DIR/$SECRET_FILENAME"

	if [[ ! -d $TARGET_DIR ]]; then
		mkdir -p $TARGET_DIR
	fi
	if [[ ! -f $SECRET_PATH ]]; then
		openssl rand -hex $SIZE > $SECRET_PATH
		return 0
	else
		return 1
	fi
}

generate_secret(){
	local SECRET_NAME=$1	
	generate_plain_hex "$SECRET_NAME.key" 64
	ret=$?

	if [ $ret -eq 1 ]; then
		yellow "Skipping $SECRET_NAME: already exists"
		return 1
	elif [ $ret -eq 0 ]; then
		echo "$SECRET_NAME generated"
		return 0
	else
		red "cannot generate $SECRET_NAME : unknown error."
		return $ret
	fi
}



generate_s3_keypair(){
	local SECRET_NAME=$1
	local BUCKET=$2
	local TARGET_DIR="secrets/plain/tokens"
	generate_plain_hex "${SECRET_NAME}-s3-id.key" 64
	ret=$?

	if [ $ret -eq 1 ]; then
		yellow "Skipping $SECRET_NAME ID: already exists"
		return 1
	elif [ $ret -eq 0 ]; then
		generate_secret "${SECRET_NAME}-s3"
	else
		red "cannot generate $SECRET_NAME ID : unknown error."
		return $ret
	fi
	cp "$TARGET_DIR/${SECRET_NAME}-s3-id.key" "$TARGET_DIR/${SECRET_NAME}-${BUCKET}-s3-id.key"
	cp "$TARGET_DIR/${SECRET_NAME}-s3-id.key" "$TARGET_DIR/${SECRET_NAME}-${BUCKET}-s3.key"
}

generate_age_keypair(){
	local VM_NAME=$1
	local TARGET_DIR="secrets/age"

	echo "Generating AGE keypair for $VM_NAME"

	if [[ ! -d $TARGET_DIR ]]; then
		mkdir -p $TARGET_DIR
	fi

	if [[ -f $TARGET_DIR/$VM_NAME.key ]]; then
		rm $TARGET_DIR/$VM_NAME.key
	fi
	
	umask 077

	age-keygen -o $TARGET_DIR/$VM_NAME.key
	age-keygen -y $TARGET_DIR/$VM_NAME.key \
		> $TARGET_DIR/$VM_NAME.pub

}

generate_step_ca(){
	
	local CA_NAME=$1

	export STEPPATH="$PWD/secrets/plain/CA"

	echo "Generating CA in $STEPPATH..."
	if [[ -d $STEPPATH ]]; then
		yellow "step-ca already initialized: skipping..."
	else
		echo "Initializing step-ca"
		install -d -m 711 $STEPPATH
		umask 077
		openssl rand -base64 48 > $STEPPATH/ca-password
		step ca init \
			--dns $CA_NAME \
			--name $CA_NAME \
			--password-file $STEPPATH/ca-password \
			--deployment-type standalone \
			--address :443 \
			--provisioner=ca
		sed -i "s+$STEPPATH+/var/lib/step-ca+" $STEPPATH/config/ca.json # patching STEPPATH
	fi


}
generate_certificate(){
	# Generates a crt/key with a ttl of 1 day for $NAME.$DOMAIn
	local DOMAIN=$1
	local NAME=$2
	local TARGET_PATH="secrets/plain/certs"
	local SAN="$NAME.$DOMAIN"
	local STEPPATH="secrets/plain/CA"

	if [[ ! -d $TARGET_PATH ]]; then
		mkdir -p $TARGET_PATH
	fi

	echo "Generating certificate for $SAN"
	step certificate create \
		$SAN $TARGET_PATH/$SAN.crt $TARGET_PATH/$SAN.key \
		--profile leaf  \
		--ca $STEPPATH/certs/intermediate_ca.crt --ca-key $STEPPATH/secrets/intermediate_ca_key \
		--san $SAN --ca-password-file $STEPPATH/ca-password \
		--no-password --insecure 

	step certificate fingerprint $STEPPATH/certs/root_ca.crt | tr -d '\n' > $STEPPATH/fingerprint # step adds a \n at the end of the line
}

generate_encrypted_certificate(){
	local DOMAIN=$1
	local RECIPIENT=$2
	local NAME=$3
	local CERT_LOCATION="secrets/plain/certs"
	local CERT_PATH="$CERT_LOCATION/$NAME.$DOMAIN.crt"
	local KEY_PATH="$CERT_LOCATION/$NAME.$DOMAIN.key"
	generate_certificate $DOMAIN $NAME
	encrypt $RECIPIENT $CERT_PATH 
	encrypt $RECIPIENT $KEY_PATH

	rm $CERT_PATH
	rm $KEY_PATH

}

encrypt(){
	local RECIPIENT=$1
	local FILEPATH=$2
	local FILENAME=$(basename $FILEPATH )

	local PUBKEY=$(cat secrets/age/$RECIPIENT.pub)

	local TARGET_DIR="secrets/encrypted"

	if [[ ! -d $TARGET_DIR ]]; then
		mkdir -p $TARGET_DIR
	fi

	sops --input-type binary --output-type binary \
		encrypt --age  $PUBKEY $FILEPATH \
		> "$TARGET_DIR/$RECIPIENT-$FILENAME.enc"

}

encrypt_secret(){
	local RECIPIENT=$1
	local TOKEN_NAME=$2
	local TOKEN_PATH="secrets/plain/tokens/$TOKEN_NAME.key"
	encrypt $RECIPIENT $TOKEN_PATH
}
encrypt_s3(){
	local RECIPIENT=$1
	local TOKEN_NAME=$2
	encrypt_secret $RECIPIENT "${TOKEN_NAME}-s3-id"
	encrypt_secret $RECIPIENT "${TOKEN_NAME}-s3"
}

encrypt_CA(){
	local RECIPIENT=$1
	encrypt $RECIPIENT "secrets/plain/CA/ca-password"
	encrypt $RECIPIENT "secrets/plain/CA/config/ca.json"
	encrypt $RECIPIENT "secrets/plain/CA/secrets/intermediate_ca_key"
	encrypt $RECIPIENT "secrets/plain/CA/certs/intermediate_ca.crt"
	encrypt $RECIPIENT "secrets/plain/CA/certs/root_ca.crt"
}
