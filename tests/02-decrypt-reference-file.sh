#!/bin/sh

### Constants
c_valgrind_min=1
reference_file="${scriptdir}/test_scrypt.good"
encrypted_reference_file="${scriptdir}/test_scrypt_good.enc"
decrypted_reference_file="${out}/attempt_reference.txt"
decrypted_badpass_file="${out}/decrypt-badpass.txt"
decrypted_badpass_log="${out}/decrypt-badpass.log"

scenario_cmd() {
	# Decrypt a reference file.
	setup_check_variables
	(
		echo ${password} | ${c_valgrind_cmd} ${bindir}/scrypt	\
		    dec -P ${encrypted_reference_file}			\
		    ${decrypted_reference_file}
		echo $? > ${c_exitfile}
	)

	# The decrypted reference file should match the reference.
	setup_check_variables
	if cmp -s ${decrypted_reference_file} ${reference_file}; then
		echo "0"
	else
		echo "1"
	fi > ${c_exitfile}

	# Attempt to decrypt the reference file with an incorrect passphrase.
	# We want this command to fail with 1.
	setup_check_variables
	(
		echo "bad-pass" | ${c_valgrind_cmd} ${bindir}/scrypt	\
		    dec -P ${encrypted_reference_file}			\
		    ${decrypted_badpass_file}				\
		    2> ${decrypted_badpass_log}
		cmd_exitcode=$?

		if [ ${cmd_exitcode} -eq "1" ]; then
			echo "0"
		elif [ ${cmd_exitcode} -eq "${valgrind_exit_code}" ]; then
			echo ${valgrind_exit_code}
		else
			echo "1"
		fi > ${c_exitfile}
	)

	# We should have received an error message.
	setup_check_variables
	if grep -q "scrypt: Passphrase is incorrect" \
	    ${decrypted_badpass_log}; then
		echo "0"
	else
		echo "1"
	fi > ${c_exitfile}
}
