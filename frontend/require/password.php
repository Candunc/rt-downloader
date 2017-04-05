<?php
class Password {
	private $config = (array)include('../require/config.php');
	private function get_AES_key() {
		# Use a 256 bit by default. Since this is so source code, I believe I am not subject to Canada's export laws.
		# Store in a seperate, hopefully read-restricted location
		$key = file_get_contents($config['aes_key']);
		if ($key === false) {
			# Add support for automatic generation of a key.
			# Is it honestly that important?
			$key = random_bytes(32);
			file_put_contents($config['aes_key'], $key);
		}

		return $key;
	}

	# Uses a similar aspect to Dropbox, however bcrypt is replaced with Argon
	# https://blogs.dropbox.com/tech/2016/09/how-dropbox-securely-stores-your-passwords/
	public function encrypt($password) {
		$argon_options = [
			'm_cost' => 2<<16,	# Memory consumption: 2^16 Kibibytes = 64 mebibytes
			't_cost' => 3,		# Number of iterations
			'threads' => 1
		];

		# http://www.zimuel.it/blog/authenticated-encrypt-with-openssl-and-php-7-1
		$aes_algo = 'aes-256-ccm';
		$aes_iv   = random_bytes(openssl_cipher_iv_length($algo));
		$aes_key  = get_AES_key();

		$pass_512   = hash('sha512', $password);
		$pass_argon = argon2_hash($pass512, HASH_ARGON2ID, $argon_options);
		$pass_aes   = openssl_encrypt($pass_argon, $aes_algo, $aes_key, OPENSSL_RAW_DATA, $aes_iv, $aes_tag);
		return $pass_aes,$aes_iv;
	}
}

?>