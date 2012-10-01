require 'base64'
require 'digest/sha1'
require 'openssl'
require 'zip/zip'

module Trackbook
  module PKPass
    extend self

    unless ENV['WWDR_CERT']
      raise "Missing Apple Worldwide Developer Relations Cert. Please set WWDR_CERT."
    end

    unless ENV['CERT']
      raise "Missing Passbook Cert. Please set CERT."
    end

    WWDR_CERT = "-----BEGIN CERTIFICATE-----\n" +
      ENV['WWDR_CERT'].scan(/.{1,64}/).join("\n") +
      "\n-----END CERTIFICATE-----\n"

    CERT = Base64.decode64(ENV['CERT'].scan(/.{1,60}/).join("\n"))
    CERT_PASS = ENV['CERT_PASS']

    def create_pkpass(files)
      manifest  = create_manifest(files)
      signature = sign_manifest(manifest)

      compress_files("pass.pkpass", files.merge({
        "manifest.json" => manifest,
        "signature" => signature
      }))
    end

    def create_manifest(files)
      files.inject({}) { |manifest, (filename, data)|
        manifest[filename] = Digest::SHA1.hexdigest(data)
        manifest
      }.to_json
    end

    def sign_manifest(manifest)
      p12   = OpenSSL::PKCS12.new(CERT, CERT_PASS)
      wwdr  = OpenSSL::X509::Certificate.new(WWDR_CERT)
      flag  = OpenSSL::PKCS7::BINARY | OpenSSL::PKCS7::DETACHED
      pk7   = OpenSSL::PKCS7.sign(p12.certificate, p12.key, manifest.to_s, [wwdr], flag)
      data  = OpenSSL::PKCS7.write_smime(pk7)

      str_debut = "filename=\"smime.p7s\"\n\n"
      data = data[data.index(str_debut)+str_debut.length..data.length-1]
      str_end = "\n\n------"
      data = data[0..data.index(str_end)-1]

      Base64.decode64(data)
    end

    def compress_files(filename, files)
      f = Tempfile.new(filename)
      Zip::ZipOutputStream.open(f.path) do |z|
        files.each do |filename, data|
          z.put_next_entry(filename)
          z.print(data)
        end
      end
      f.read
    ensure
      f.close
    end
  end
end
